import Foundation
import SwiftData

@Model
final class Movie {
    @Attribute(.unique) var id: UUID
    var title: String
    var normalizedTitle: String
    var releaseYear: Int?
    var statusRawValue: String
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
        self.rating = RatingRules.validated(rating, for: status)
        self.synopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coverFilename = coverFilename
        self.tierRawValue = tier?.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.genres = genres
    }

    var status: ViewingStatus {
        get { ViewingStatus(rawValue: statusRawValue) ?? .wantToWatch }
        set {
            statusRawValue = newValue.rawValue
            rating = RatingRules.validated(rating, for: newValue)
        }
    }

    var tier: MovieTier? {
        get { tierRawValue.flatMap(MovieTier.init(rawValue:)) }
        set { tierRawValue = newValue?.rawValue }
    }

    func update(
        title: String,
        releaseYear: Int?,
        status: ViewingStatus,
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
        self.rating = RatingRules.validated(rating, for: status)
        self.synopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coverFilename = coverFilename
        self.genres = genres
        updatedAt = now
    }
}
