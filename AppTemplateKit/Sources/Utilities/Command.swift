//
//  Command.swift
//  AppTemplateKit
//
//  Created by Harley Pham on 27/11/24.
//

import Foundation

enum Command {
    // runs shell command synchronously and returns an output
    @discardableResult
    public static func runShellCommand(_ command: String) -> String {
        let pipe = Pipe()
        let process = Process()

        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        let file = pipe.fileHandleForReading

        process.launch()

        guard let result = String(data: file.readDataToEndOfFile(), encoding: .utf8) else {
            logger.error("XcodeFiles: Error while reading output from shell command: \(command)")
            return ""
        }

        return result
    }
}
