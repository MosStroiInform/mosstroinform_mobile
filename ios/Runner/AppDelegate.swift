import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Настраиваем notification center delegate для обработки уведомлений о скачивании
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
