import UIKit
import Firebase
import SmartSubscriptionKit
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        FirebaseApp.configure()
//        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
//        AppEventLogger.logger = FirebaseEventLogger.shared
        SmartSubscriptionIAPManager.shared.startObserving()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SmartSubscriptionIAPManager.shared.stopObserving()
    }
}
