//
//  FirebaseEventLogger.swift
//  AppTemplate
//
//  Created by Phong Tran 2 on 12/9/24.
//

import AppTemplateKit
import FirebaseCore
import FirebaseFirestore
import os

final class FirebaseEventLogger: AppEventLoggable {
    private let db = Firestore.firestore()

    static let shared = FirebaseEventLogger()

    func log(eventName: String, params: [String: Any]) async throws {
        // Add a new document with a generated ID
        Logger(subsystem: "FirebaseEventLogger", category: "Logging")
            .info("Logging event: \(eventName) with params: \(params)")
        let isAppSandbox: Bool = {
#if APP_SANDBOX
            true
#else
            false
#endif
        }()
        do {
            let ref = try await db.collection("logs").addDocument(data: [
                "app-sandbox": isAppSandbox,
                "event-name": eventName,
                "timestamp": Date().timeIntervalSince1970,
                "install-id": Preferences.shared.installID
            ].merging(params, uniquingKeysWith: { $1 }))
          print("Document added with ID: \(ref.documentID)")
        } catch {
          print("Error adding document: \(error)")
        }
    }
}
