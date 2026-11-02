package ch.strokesplit.strokesplit

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/** A fragment activity, as Health Connect asks for its permissions through an activity result (Design D7). */
class MainActivity : FlutterFragmentActivity() {
    private var healthConnect: HealthConnectChannel? = null
    private lateinit var permissions: HealthConnectPermissions

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before the activity starts, as activity results require.
        permissions = HealthConnectPermissions(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        healthConnect = HealthConnectChannel(this, permissions, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        healthConnect?.onNewIntent(intent)
    }
}
