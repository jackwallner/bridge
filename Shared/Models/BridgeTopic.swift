import Foundation

/// Beginner Standard American opening choices used by hand-reading drills.
enum HandCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case pass
    case oneClub
    case oneDiamond
    case oneHeart
    case oneSpade
    case oneNotrump

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pass: return "Pass"
        case .oneClub: return "1♣"
        case .oneDiamond: return "1♦"
        case .oneHeart: return "1♥"
        case .oneSpade: return "1♠"
        case .oneNotrump: return "1NT"
        }
    }
}
