package com.example.sahasi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.telephony.SmsManager
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sahasi_sos_channel"
    private var methodChannel: MethodChannel? = null
    
    // Ringtone variable
    private var ringtone: Ringtone? = null

    // Button Logic Variables
    private var buttonClicks = 0
    private var lastClickTime = 0L
    private val CLICK_THRESHOLD = 1500L // Increased threshold for easier clicking
    private var requiredClicks = 3 // Default

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendBackgroundSMS" -> {
                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")
                    sendSMS(number, message, result)
                }
                "makeDirectCall" -> {
                    val number = call.argument<String>("number")
                    makeCall(number, result)
                }
                "playRingtone" -> {
                    playDefaultRingtone(result)
                }
                "stopRingtone" -> {
                    stopDefaultRingtone(result)
                }
                "setSOSThreshold" -> {
                    val count = call.argument<Int>("count")
                    if (count != null) {
                        requiredClicks = count
                        result.success("Threshold set to $requiredClicks")
                    } else {
                        result.error("INVALID_ARGS", "Count missing", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_ON)
        filter.addAction(Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenReceiver, filter)
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
        stopDefaultRingtone(null)
        super.onDestroy()
    }

    // --- Volume Button Capture ---
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val action = event.action
        val keyCode = event.keyCode
        
        if (action == KeyEvent.ACTION_DOWN) {
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                checkButtonClicks()
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // --- Button Click Logic ---
    private fun checkButtonClicks() {
        val currentTime = System.currentTimeMillis()
        
        if (currentTime - lastClickTime > CLICK_THRESHOLD) {
            buttonClicks = 0
        }
        
        buttonClicks++
        lastClickTime = currentTime

        // Logic: Trigger if clicks match requirement. 
        // Note: Reset immediately to prevent multiple triggers in one rapid sequence.
        if (buttonClicks == requiredClicks) {
            buttonClicks = 0 // Reset
            triggerVibration()
            runOnUiThread {
                methodChannel?.invokeMethod("onNativeSOS", null)
            }
        }
    }

    private fun triggerVibration() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(500)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_SCREEN_ON || intent.action == Intent.ACTION_SCREEN_OFF) {
                checkButtonClicks()
            }
        }
    }

    // --- SMS Sending ---
    private fun sendSMS(number: String?, message: String?, result: MethodChannel.Result) {
        if (number == null || message == null) {
            result.error("INVALID_ARGS", "Number or message missing", null)
            return
        }
        try {
            val smsManager = SmsManager.getDefault()
            // Split long messages to ensure delivery
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(number, null, parts, null, null)
            result.success("SMS Sent")
        } catch (e: Exception) {
            // Log the error for debugging
            android.util.Log.e("SMS_ERROR", "Failed to send SMS: ${e.message}")
            result.error("SMS_ERROR", e.message, null)
        }
    }

    // --- Calling ---
    private fun makeCall(number: String?, result: MethodChannel.Result) {
        if (number == null) {
            result.error("INVALID_ARGS", "Number missing", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$number")
            startActivity(intent)
            result.success("Call Started")
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    // --- Ringtone ---
    private fun playDefaultRingtone(result: MethodChannel.Result) {
        try {
            if (ringtone == null) {
                val notification = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ringtone = RingtoneManager.getRingtone(applicationContext, notification)
            }
            if (ringtone?.isPlaying == false) {
                ringtone?.play()
            }
            result.success("Playing")
        } catch (e: Exception) {
            result.error("RINGTONE_ERROR", e.message, null)
        }
    }

    private fun stopDefaultRingtone(result: MethodChannel.Result?) {
        try {
            ringtone?.stop()
            result?.success("Stopped")
        } catch (e: Exception) {
            result?.error("RINGTONE_ERROR", e.message, null)
        }
    }
}