import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthChannelName = "com.hartvig_solutions.tread_runner/health"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let healthChannel = FlutterMethodChannel(
      name: healthChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    healthChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleHealthMethod(call: call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleHealthMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      DispatchQueue.global().async {
        // TODO: Integrate HealthKit authorization flow.
        result(true)
      }
    case "writeWorkout":
      DispatchQueue.global().async {
        // TODO: Persist workout to HealthKit.
        result(false)
      }
    case "readLatestHeartRate":
      DispatchQueue.global().async {
        // TODO: Query HealthKit for latest heart rate.
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
