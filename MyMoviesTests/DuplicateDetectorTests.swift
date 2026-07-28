import Foundation
import Testing
@testable import MyMovies

struct DuplicateDetectorTests {
    @Test
    func ignoresCaseAndExtraWhitespace() {
        let movie = DuplicateCandidate(id: UUID(), title: "The   Matrix", releaseYear: 1999)

        #expect(
            DuplicateDetector.containsDuplicate(
                title: "  the matrix ",
                releaseYear: 1999,
                in: [movie]
            )
        )
    }

    @Test
    func treatsTwoMissingYearsAsEqual() {
        let movie = DuplicateCandidate(id: UUID(), title: "Arrival", releaseYear: nil)
        #expect(DuplicateDetector.containsDuplicate(title: "arrival", releaseYear: nil, in: [movie]))
    }

    @Test
    func permitsSameTitleWithDifferentYearAndExcludesCurrentMovie() {
        let id = UUID()
        let movie = DuplicateCandidate(id: id, title: "Dune", releaseYear: 1984)
        #expect(!DuplicateDetector.containsDuplicate(title: "Dune", releaseYear: 2021, in: [movie]))
        #expect(!DuplicateDetector.containsDuplicate(title: "Dune", releaseYear: 1984, excluding: id, in: [movie]))
    }
}
