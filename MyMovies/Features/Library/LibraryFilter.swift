import SwiftUI

enum LibraryFilter: Hashable, Identifiable {
    case all
    case favorites
    case tierList
    case status(ViewingStatus)

    var id: String {
        switch self {
        case .all: "all"
        case .favorites: "favorites"
        case .tierList: "tier-list"
        case .status(let status): status.rawValue
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "All Movies"
        case .favorites: "Favorite"
        case .tierList: "Tier List"
        case .status(let status): status.titleKey
        }
    }

    var systemImage: String {
        switch self {
        case .all: "film.stack"
        case .favorites: "heart.fill"
        case .tierList: "square.grid.3x3.square"
        case .status(let status): status.systemImage
        }
    }
}
