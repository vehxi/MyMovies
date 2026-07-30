import SwiftData
import Testing
@testable import MyMovies

struct StatusCounterTests {
    @Test
    func countsStatusesAndFavoritesIndependently() {
        let snapshots = [
            StatusSnapshot(status: .watched),
            StatusSnapshot(status: .watched, isFavorite: true),
            StatusSnapshot(status: .watching, isFavorite: true),
            StatusSnapshot(status: .watching)
        ]

        let counts = StatusCounter.counts(snapshots)
        #expect(counts[.watched] == 2)
        #expect(counts[.watching] == 2)
        #expect(StatusCounter.favoriteCount(snapshots) == 2)
        #expect(snapshots.filter(\.status.isWatched).count == 2)
    }

    @Test
    func legacyFavoriteStatusBecomesWatchedAndFavorite() {
        let movie = Movie(title: "Legacy")
        movie.statusRawValue = "favorite"

        #expect(movie.status == .watched)
        #expect(movie.isFavorite)

        movie.status = .watching

        #expect(movie.status == .watching)
        #expect(movie.isFavorite)
    }

    @MainActor
    @Test
    func migratesLegacyFavoriteStatusInPersistentStore() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let movie = Movie(title: "Legacy")
        movie.statusRawValue = "favorite"
        context.insert(movie)
        try context.save()

        try PersistenceController.migrateLegacyFavorites(in: context)

        let storedMovie = try #require(context.fetch(FetchDescriptor<Movie>()).first)
        #expect(storedMovie.statusRawValue == ViewingStatus.watched.rawValue)
        #expect(storedMovie.favoriteFlag)
    }
}
