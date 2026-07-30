import Foundation
import SwiftData

@Model
final class Movie {
    private static let legacyFavoriteStatus = "favorite"

    @Attribute(.unique) var id: UUID
    var title: String
    var normalizedTitle: String
    var releaseYear: Int?
    var statusRawValue: String
    var favoriteFlag: Bool = false
    var rating: Int?
    var synopsis: String
    var coverFilename: String?
    var tierRawValue: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Genre.movies)
    var genres: [Genre]

    init(
        id: UUID = UUID(),
        title: String,
        releaseYear: Int? = nil,
        status: ViewingStatus = .wantToWatch,
        isFavorite: Bool = false,
        rating: Int? = nil,
        synopsis: String = "",
        coverFilename: String? = nil,
        tier: MovieTier? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        genres: [Genre] = []
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.normalizedTitle = TextNormalizer.normalize(title)
        self.releaseYear = releaseYear
        self.statusRawValue = status.rawValue
        self.favoriteFlag = isFavorite
        self.rating = RatingRules.validated(rating, for: status)
        self.synopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coverFilename = coverFilename
        self.tierRawValue = tier?.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.genres = genres
    }

    var status: ViewingStatus {
        get {
            if statusRawValue == Self.legacyFavoriteStatus {
                return .watched
            }
            return ViewingStatus(rawValue: statusRawValue) ?? .wantToWatch
        }
        set {
            if statusRawValue == Self.legacyFavoriteStatus {
                favoriteFlag = true
            }
            statusRawValue = newValue.rawValue
            rating = RatingRules.validated(rating, for: newValue)
        }
    }

    var isFavorite: Bool {
        get { favoriteFlag || statusRawValue == Self.legacyFavoriteStatus }
        set {
            favoriteFlag = newValue
            if statusRawValue == Self.legacyFavoriteStatus {
                statusRawValue = ViewingStatus.watched.rawValue
            }
        }
    }

    @discardableResult
    func migrateLegacyFavoriteIfNeeded() -> Bool {
        guard statusRawValue == Self.legacyFavoriteStatus else { return false }
        favoriteFlag = true
        statusRawValue = ViewingStatus.watched.rawValue
        return true
    }

    var tier: MovieTier? {
        get { tierRawValue.flatMap(MovieTier.init(rawValue:)) }
        set { tierRawValue = newValue?.rawValue }
    }

    func update(
        title: String,
        releaseYear: Int?,
        status: ViewingStatus,
        isFavorite: Bool,
        rating: Int?,
        synopsis: String,
        coverFilename: String?,
        genres: [Genre],
        now: Date = .now
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedTitle = TextNormalizer.normalize(title)
        self.releaseYear = releaseYear
        statusRawValue = status.rawValue
        favoriteFlag = isFavorite
        self.rating = RatingRules.validated(rating, for: status)
        self.synopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coverFilename = coverFilename
        self.genres = genres
        updatedAt = now
    }
}
