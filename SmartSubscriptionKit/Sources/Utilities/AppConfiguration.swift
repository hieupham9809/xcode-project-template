import Foundation

public struct AppConfiguration: Sendable {
    public static var openAIAPIKey: String {
        return Secrets.openAIAPIKey
    }
    
    public static var openAIModel: String {
        return "gpt-4o"
    }
}
