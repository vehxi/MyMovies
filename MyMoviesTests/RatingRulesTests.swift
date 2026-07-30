import Testing
@testable import MyMovies

struct RatingRulesTests {
    @Test
    func permitsRatingsForWatchedStatuses() {
        #expect(RatingRules.validated(4, for: .watched) == 4)
    }

    @Test
    func rejectsRatingsForOtherStatusesAndOutOfRangeValues() {
        #expect(RatingRules.validated(3, for: .watching) == nil)
        #expect(RatingRules.validated(0, for: .watched) == nil)
        #expect(RatingRules.validated(6, for: .watched) == nil)
    }
}
