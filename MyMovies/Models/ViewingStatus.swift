import Foundation
import SwiftUI

enum ViewingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case wantToWatch
    case watching
    case watched
    case abandoned
    case favorite

    var id: String { rawValue }

    var isWatched: Bool {
        self == .watched || self == .favorite
    }

    var allowsRating: Bool { isWatched }

    var titleKey: LocalizedStringKey {
        switch self {
        case .wantToWatch: "Want to Watch"
        case .watching: "Watching"
        case .watched: "Watched"
        case .abandoned: "Abandoned"
        case .favorite: "Favorite"
        }
    }

    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .wantToWatch:
            AppLocalization.string("Want to Watch", locale: locale)
        case .watching:
            AppLocalization.string("Watching", locale: locale)
        case .watched:
            AppLocalization.string("Watched", locale: locale)
        case .abandoned:
            AppLocalization.string("Abandoned", locale: locale)
        case .favorite:
            AppLocalization.string("Favorite", locale: locale)
        }
    }

    var systemImage: String {
        switch self {
        case .wantToWatch: "bookmark"
        case .watching: "play.circle"
        case .watched: "checkmark.circle"
        case .abandoned: "xmark.circle"
        case .favorite: "heart.fill"
        }
    }
}
