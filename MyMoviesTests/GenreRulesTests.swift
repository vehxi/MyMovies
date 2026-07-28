import Foundation
import SwiftData
import Testing
@testable import MyMovies

struct GenreRulesTests {
    @Test
    func normalizesGenreNames() {
        #expect(TextNormalizer.displayName("  Science   Fiction\n") == "Science Fiction")
        #expect(TextNormalizer.normalize("  ДРАМА ") == TextNormalizer.normalize("драма"))
    }

    @Test
    func rejectsNormalizedDuplicates() {
        let id = UUID()
        #expect(GenreRules.isDuplicate(name: "  drama ", among: [(id, "Drama")]))
        #expect(!GenreRules.isDuplicate(name: "Drama", excluding: id, among: [(id, "Drama")]))
    }

    @Test
    func removesOnlyDeletedGenreRelationship() {
        let deleted = UUID()
        let retained = UUID()
        #expect(GenreRules.removing(genreID: deleted, from: [deleted, retained]) == [retained])
    }

    @MainActor
    @Test
    func deletingPersistedGenreKeepsMovieAndRemovesRelationship() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let genre = Genre(name: "Drama")
        let movie = Movie(title: "Arrival", genres: [genre])
        context.insert(genre)
        context.insert(movie)
        try context.save()

        context.delete(genre)
        try context.save()

        let remainingMovies = try context.fetch(FetchDescriptor<Movie>())
        #expect(remainingMovies.count == 1)
        #expect(remainingMovies[0].genres.isEmpty)
    }
}
