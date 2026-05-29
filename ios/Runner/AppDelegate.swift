import Flutter
import GoogleSignIn
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required when Google Cloud/Firebase "Google Identity for iOS" App Check is enforced.
    // See: https://developers.google.com/identity/sign-in/ios/appcheck/get-started
    #if !targetEnvironment(simulator)
    GIDSignIn.sharedInstance.configure { error in
      if let error {
        NSLog("GIDSignIn App Check configure error: \(error.localizedDescription)")
      }
    }
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
