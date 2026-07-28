import Testing
@testable import MyMovies

struct StatusCounterTests {
    @Test
    func countsMutuallyExclusiveStatuses() {
        let snapshots = [
            StatusSnapshot(status: .watched),
            StatusSnapshot(status: .favorite),
            StatusSnapshot(status: .favorite),
            StatusSnapshot(status: .watching)
        ]

        let counts = StatusCounter.counts(snapshots)
        #expect(counts[.watched] == 1)
        #expect(counts[.favorite] == 2)
        #expect(counts[.watching] == 1)
        #expect(snapshots.filter(\.status.isWatched).count == 3)
    }
}
