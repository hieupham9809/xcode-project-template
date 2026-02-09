import SwiftUI

public enum KnownService: String, CaseIterable, Codable {
    case netflix = "Netflix"
    case spotify = "Spotify"
    case youtube = "YouTube"
    case youtubePremium = "YouTube Premium"
    case apple = "Apple"
    case appleMusic = "Apple Music"
    case appleTVPlus = "Apple TV+"
    case iCloud = "iCloud"
    case amazonPrime = "Amazon Prime"
    case disneyPlus = "Disney+"
    case hbo = "HBO Max"
    case hulu = "Hulu"
    case microsoft365 = "Microsoft 365"
    case dropbox = "Dropbox"
    case googleOne = "Google One"
    case notion = "Notion"
    case slack = "Slack"
    case zoom = "Zoom"
    case github = "GitHub"
    case adobe = "Adobe"
    case canva = "Canva"
    case figma = "Figma"
    case chatgpt = "ChatGPT"
    case openai = "OpenAI"
    case claude = "Claude"
    case x = "X"
    case twitter = "Twitter"
    case linkedin = "LinkedIn"
    case twitch = "Twitch"
    case discord = "Discord"

    public var iconName: String {
        switch self {
        case .netflix: return "play.tv.fill" // SF Symbol approximation
        case .spotify: return "music.note"
        case .youtube, .youtubePremium: return "play.rectangle.fill"
        case .apple, .appleMusic, .appleTVPlus, .iCloud: return "apple.logo"
        case .amazonPrime: return "cart.fill"
        case .disneyPlus: return "play.circle.fill" // Generic play
        case .hbo, .hulu: return "tv.fill"
        case .microsoft365: return "square.grid.2x2.fill"
        case .dropbox: return "archivebox.fill"
        case .googleOne: return "cloud.fill"
        case .notion: return "doc.text.fill"
        case .slack: return "bubble.left.and.bubble.right.fill"
        case .zoom: return "video.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .adobe: return "pencil.tip.crop.circle"
        case .canva: return "paintbrush.fill"
        case .figma: return "pencil.and.outline"
        case .chatgpt, .openai: return "brain.head.profile"
        case .claude: return "sparkles"
        case .x, .twitter: return "at"
        case .linkedin: return "person.crop.square.fill"
        case .twitch: return "gamecontroller.fill"
        case .discord: return "bubble.left.fill"
        }
    }

    public var brandColor: Color {
        switch self {
        case .netflix: return Color(hex: 0xE50914)
        case .spotify: return Color(hex: 0x1DB954)
        case .youtube, .youtubePremium: return Color(hex: 0xFF0000)
        case .apple, .appleMusic, .appleTVPlus, .iCloud: return .primary // Adaptive black/white
        case .amazonPrime: return Color(hex: 0x00A8E1)
        case .disneyPlus: return Color(hex: 0x113CCF)
        case .hbo: return Color(hex: 0x5822B4)
        case .hulu: return Color(hex: 0x1CE783)
        case .microsoft365: return Color(hex: 0x0078D4)
        case .dropbox: return Color(hex: 0x0061FF)
        case .googleOne: return Color(hex: 0x4285F4)
        case .notion: return .primary
        case .slack: return Color(hex: 0x4A154B)
        case .zoom: return Color(hex: 0x2D8CFF)
        case .github: return .primary
        case .adobe: return Color(hex: 0xFF0000)
        case .canva: return Color(hex: 0x00C4CC)
        case .figma: return Color(hex: 0xF24E1E)
        case .chatgpt, .openai: return Color(hex: 0x74AA9C)
        case .claude: return Color(hex: 0xD97757)
        case .x, .twitter: return .black
        case .linkedin: return Color(hex: 0x0077B5)
        case .twitch: return Color(hex: 0x9146FF)
        case .discord: return Color(hex: 0x5865F2)
        }
    }
}

public struct ServiceIconRegistry {
    public static func detectService(name: String, provider: String?) -> KnownService? {
        // Simple case-insensitive match
        // Can be improved with fuzzy matching or "contains" logic
        
        // 1. Check exact match on name
        if let service = KnownService(rawValue: name) { return service }
        
        // 2. Check case-insensitive
        let lowerName = name.lowercased()
        if let service = KnownService.allCases.first(where: { $0.rawValue.lowercased() == lowerName }) {
            return service
        }
        
        // 3. Check contains (e.g. "Netflix Premium" -> Netflix)
        // Sort by length detailed to avoid matching "App" to "Apple" incorrectly if "App" was a service (not here though)
        // But generally "Netflix Premium" should match "Netflix"
        if let service = KnownService.allCases.first(where: { lowerName.contains($0.rawValue.lowercased()) }) {
            return service
        }
        
        // 4. Check specific provider aliases if needed (future)
        
        return nil
    }
    
    public static func icon(for service: KnownService) -> Image {
        Image(systemName: service.iconName)
    }
    
    public static func color(for service: KnownService) -> Color {
        service.brandColor
    }
}

// Helper for Color from Hex
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
