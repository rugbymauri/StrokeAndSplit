package ch.strokesplit.strokesplit

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.PowerRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SpeedRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.lifecycle.lifecycleScope
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import kotlin.reflect.KClass

/** The record types the app writes, by the names Dart uses for them. */
internal val healthKinds: Map<String, KClass<out Record>> = mapOf(
    "exercise" to ExerciseSessionRecord::class,
    "distance" to DistanceRecord::class,
    "calories" to TotalCaloriesBurnedRecord::class,
    "heartRate" to HeartRateRecord::class,
    "power" to PowerRecord::class,
    "speed" to SpeedRecord::class,
)

internal fun writePermission(kind: String): String = HealthPermission.getWritePermission(healthKinds.getValue(kind))

/** Asks Health Connect for permissions; registered while the activity is created. */
class HealthConnectPermissions(activity: FragmentActivity) {
    private var pending: ((Set<String>) -> Unit)? = null
    private val launcher: ActivityResultLauncher<Set<String>> =
        activity.registerForActivityResult(PermissionController.createRequestPermissionResultContract()) { granted ->
            pending?.invoke(granted)
            pending = null
        }

    fun request(permissions: Set<String>, onResult: (Set<String>) -> Unit) {
        pending = onResult
        launcher.launch(permissions)
    }
}

/**
 * The channel `ch.strokesplit/health_connect` to Health Connect (Change health-connect, Design D1). It writes
 * what Dart hands it and knows nothing about sessions.
 */
class HealthConnectChannel(
    private val activity: FragmentActivity,
    private val permissions: HealthConnectPermissions,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }

    private val client: HealthConnectClient?
        get() = if (status() == "available") HealthConnectClient.getOrCreate(activity) else null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "grantedPermissions" -> withClient(result) { client ->
                result.success(grantedKinds(client.permissionController.getGrantedPermissions()))
            }
            "requestPermissions" -> {
                val kinds = call.arguments<List<String>>().orEmpty()
                permissions.request(kinds.map(::writePermission).toSet()) { granted ->
                    result.success(grantedKinds(granted))
                }
            }
            "openInstall" -> {
                openInstall()
                result.success(null)
            }
            "openSettings" -> {
                activity.startActivity(Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS))
                result.success(null)
            }
            "launchAction" -> result.success(launchAction(activity.intent))
            else -> result.notImplemented()
        }
    }

    fun onNewIntent(intent: Intent) {
        launchAction(intent)?.let { channel.invokeMethod("launchAction", it) }
    }

    private fun status(): String = when (HealthConnectClient.getSdkStatus(activity, PROVIDER)) {
        HealthConnectClient.SDK_AVAILABLE -> "available"
        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "updateRequired"
        else -> "unavailable"
    }

    private fun grantedKinds(granted: Set<String>): List<String> =
        healthKinds.keys.filter { granted.contains(writePermission(it)) }

    /** Runs [block] with the client, or fails with `unavailable` without Health Connect. */
    private fun withClient(result: MethodChannel.Result, block: suspend (HealthConnectClient) -> Unit) {
        val client = client ?: return result.error("unavailable", "Health Connect is not available", null)
        activity.lifecycleScope.launch {
            try {
                block(client)
            } catch (e: SecurityException) {
                result.error("permission", e.message, null)
            } catch (e: Exception) {
                result.error("failed", e.message, null)
            }
        }
    }

    private fun openInstall() {
        val uri = Uri.parse("market://details?id=$PROVIDER&url=healthconnect%3A%2F%2Fonboarding")
        activity.startActivity(
            Intent(Intent.ACTION_VIEW, uri).setPackage("com.android.vending").putExtra("overlay", true),
        )
    }

    /** `privacy` when Health Connect opened the app for its privacy notice. */
    private fun launchAction(intent: Intent?): String? = when (intent?.action) {
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE", "android.intent.action.VIEW_PERMISSION_USAGE" -> "privacy"
        else -> null
    }

    companion object {
        const val NAME = "ch.strokesplit/health_connect"
        const val PROVIDER = "com.google.android.apps.healthdata"
    }
}
