package ch.strokesplit.strokesplit

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseLap
import androidx.health.connect.client.records.ExerciseSegment
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.PowerRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SpeedRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.records.metadata.Device
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.Energy
import androidx.health.connect.client.units.Length
import androidx.health.connect.client.units.Power
import androidx.health.connect.client.units.Velocity
import androidx.lifecycle.lifecycleScope
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
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
            "writeSession" -> withClient(result) { client ->
                writeSession(client, call.arguments<Map<String, Any?>>()!!)
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

    /**
     * Replaces what an earlier write left of the session with [workout] (Design D2): first the own records of
     * the granted types in its time are deleted, then all records go in at once. Types without permission
     * are left out; without the one for workouts nothing is written.
     */
    private suspend fun writeSession(client: HealthConnectClient, workout: Map<String, Any?>) {
        val granted = grantedKinds(client.permissionController.getGrantedPermissions()).toSet()
        if ("exercise" !in granted) throw SecurityException("Writing workouts is not permitted")
        val records = SessionRecords(workout).build(granted)
        val end = instant(workout["end"]).plusSeconds(1)
        for (kind in granted) {
            client.deleteRecords(healthKinds.getValue(kind), TimeRangeFilter.between(instant(workout["start"]), end))
        }
        client.insertRecords(records)
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

private fun instant(value: Any?): Instant = Instant.ofEpochMilli((value as Number).toLong())

private fun offset(at: Instant): ZoneOffset = ZoneId.systemDefault().rules.getOffset(at)

/** The records of a session from the map Dart sends (see `HealthWorkout.toChannel`). */
private class SessionRecords(private val workout: Map<String, Any?>) {
    private val id = workout["id"] as String
    private val version = (workout["version"] as Number).toLong()
    private val start = instant(workout["start"])
    private val end = instant(workout["end"])

    private fun metadata(suffix: String) =
        Metadata.activelyRecorded(Device(type = Device.TYPE_UNKNOWN), "$id-$suffix", version)

    fun build(granted: Set<String>): List<Record> = buildList {
        add(exercise())
        if ("distance" in granted) {
            add(
                DistanceRecord(
                    startTime = start, startZoneOffset = offset(start), endTime = end, endZoneOffset = offset(end),
                    distance = Length.meters((workout["meters"] as Number).toDouble()), metadata = metadata("distance"),
                ),
            )
        }
        val kilocalories = workout["kilocalories"] as Number?
        if (kilocalories != null && "calories" in granted) {
            add(
                TotalCaloriesBurnedRecord(
                    startTime = start, startZoneOffset = offset(start), endTime = end, endZoneOffset = offset(end),
                    energy = Energy.kilocalories(kilocalories.toDouble()), metadata = metadata("calories"),
                ),
            )
        }
        if ("heartRate" in granted) {
            series("heartRate") { time, value, parts ->
                HeartRateRecord(
                    parts.first, offset(parts.first), parts.second, offset(parts.second),
                    time.map { (t, v) -> HeartRateRecord.Sample(t, v.toLong()) }, value,
                )
            }.let(::addAll)
        }
        if ("power" in granted) {
            series("power") { time, value, parts ->
                PowerRecord(
                    parts.first, offset(parts.first), parts.second, offset(parts.second),
                    time.map { (t, v) -> PowerRecord.Sample(t, Power.watts(v)) }, value,
                )
            }.let(::addAll)
        }
        if ("speed" in granted) {
            series("speed") { time, value, parts ->
                SpeedRecord(
                    parts.first, offset(parts.first), parts.second, offset(parts.second),
                    time.map { (t, v) -> SpeedRecord.Sample(t, Velocity.metersPerSecond(v)) }, value,
                )
            }.let(::addAll)
        }
    }

    private fun exercise(): ExerciseSessionRecord = ExerciseSessionRecord(
        startTime = start,
        startZoneOffset = offset(start),
        endTime = end,
        endZoneOffset = offset(end),
        metadata = metadata("exercise"),
        exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE,
        title = workout["title"] as String?,
        segments = list("segments").map {
            ExerciseSegment(
                instant(it[0]),
                instant(it[1]),
                if (it[2] == "pause") {
                    ExerciseSegment.EXERCISE_SEGMENT_TYPE_PAUSE
                } else {
                    ExerciseSegment.EXERCISE_SEGMENT_TYPE_ROWING_MACHINE
                },
            )
        },
        laps = list("laps").map {
            ExerciseLap(instant(it[0]), instant(it[1]), Length.meters((it[2] as Number).toDouble()))
        },
    )

    @Suppress("UNCHECKED_CAST")
    private fun list(key: String): List<List<Any?>> = workout[key] as List<List<Any?>>? ?: emptyList()

    /** The parts of a series; [record] gets the samples, the metadata and the start and end of a part. */
    @Suppress("UNCHECKED_CAST")
    private fun series(
        kind: String,
        record: (List<Pair<Instant, Double>>, Metadata, Pair<Instant, Instant>) -> Record,
    ): List<Record> = (workout[kind] as List<Map<String, Any?>>? ?: emptyList()).map { part ->
        val samples = (part["samples"] as List<List<Any?>>).map { instant(it[0]) to (it[1] as Number).toDouble() }
        val suffix = (part["id"] as String).removePrefix("$id-")
        record(samples, metadata(suffix), instant(part["start"]) to instant(part["end"]))
    }
}
