//
//  AppUpdateManager.swift
//  AppTemplate
//
//  Created by Harley Pham on 2/10/24.
//

#if !APP_SANDBOX
import Foundation
import Sparkle

final class AppUpdateManager: NSObject {
    let updateController: SPUStandardUpdaterController

    static let shared = AppUpdateManager()

    private override init() {
        updateController = SPUStandardUpdaterController(
            updaterDelegate: AppUpdateManagerUpdaterDelegate(),
            userDriverDelegate: AppUpdateManagerUserDriverDelegate()
        )
        super.init()
        updateController.updater.clearFeedURLFromUserDefaults()
        updateController.startUpdater()

        self.updateController.checkForUpdates(nil)
    }
}

final class AppUpdateManagerUpdaterDelegate: NSObject, SPUUpdaterDelegate {

}

final class AppUpdateManagerUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {

}
#endif
