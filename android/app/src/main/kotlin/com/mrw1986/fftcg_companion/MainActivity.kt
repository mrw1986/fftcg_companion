package com.mrw1986.fftcg_companion

import android.os.Bundle
import android.widget.Toast
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mrw1986.fftcg_companion/back_handler"
    private var methodChannel: MethodChannel? = null
    private var lastBackPressTime: Long = 0
    private val DOUBLE_BACK_PRESS_INTERVAL = 2000 // 2 seconds

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                handleBackPress()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enablePredictiveBack" -> {
                    result.success(null)
                }
                "exitApp" -> {
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleBackPress() {
        methodChannel?.invokeMethod("handleBackPress", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (result is Boolean && !result) {
                    val currentTime = System.currentTimeMillis()
                    if (currentTime - lastBackPressTime <= DOUBLE_BACK_PRESS_INTERVAL) {
                        finish()
                    } else {
                        lastBackPressTime = currentTime
                        Toast.makeText(
                            this@MainActivity,
                            "Press back again to exit",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // Handle error if needed
            }
            
            override fun notImplemented() {
                // Handle not implemented if needed
            }
        })
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            handleBackPress()
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }
}
