import Flutter
import UIKit

public class CybersourceInappPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cybersource_inapp", binaryMessenger: registrar.messenger())
    let instance = CybersourceInappPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCaptureContext":
      // TODO: Replace with real capture context from backend / Cybersource SDK.
      // For now we return a simple dummy value so that the Flutter side can
      // complete the payment flow in development.
      result("DUMMY_CAPTURE_CONTEXT_IOS")

    case "tokenizeCard":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(
          code: "BAD_ARGS",
          message: "Invalid arguments for tokenizeCard",
          details: nil
        ))
        return
      }

      let cardNumber = (args["cardNumber"] as? String) ?? ""
      let last4 = String(cardNumber.suffix(4))
      let dummyToken = "CS_IOS_TRANSIENT_TOKEN_\(last4)"
      // In a real implementation this is where you would call the Cybersource
      // iOS In‑app SDK with the captureContext and card data to obtain a
      // transient token.
      result(dummyToken)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
