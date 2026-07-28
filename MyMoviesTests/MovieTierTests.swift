import Testing
@testable import MyMovies

struct MovieTierTests {
    @Test
    func newMoviesStartUnranked() {
        let movie = Movie(title: "Arrival")

        #expect(movie.tier == nil)
        #expect(movie.tierRawValue == nil)
    }

    @Test
    func tierRoundTripsThroughPersistedRawValue() {
        let movie = Movie(title: "The Matrix", tier: .s)

        #expect(movie.tier == .s)
        #expect(movie.tierRawValue == "s")

        movie.tier = .c
        #expect(movie.tierRawValue == "c")
    }

    @Test
    func unknownPersistedTierFallsBackToUnranked() {
        let movie = Movie(title: "Dune")
        movie.tierRawValue = "unknown"

        #expect(movie.tier == nil)
    }
}
