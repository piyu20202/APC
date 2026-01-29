package com.apc.cybersource_inapp

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** CybersourceInappPlugin */
class CybersourceInappPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cybersource_inapp")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }

      "getCaptureContext" -> {
        // Abhi ke liye dummy capture context – sirf testing flow ke liye
        result.success("DUMMY_CAPTURE_CONTEXT_ANDROID")
      }

      "tokenizeCard" -> {
        // Dummy transient token: sirf card ke last 4 digits laga kar
        val cardNumber = call.argument<String>("cardNumber") ?: ""
        val last4 = if (cardNumber.length >= 4) {
          cardNumber.takeLast(4)
        } else {
          cardNumber
        }
        val dummyToken = "CS_ANDROID_TRANSIENT_TOKEN_$last4"
        result.success(dummyToken)
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

