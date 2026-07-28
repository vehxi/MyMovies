struct StatusSnapshot: Equatable {
    let status: ViewingStatus
}

enum StatusCounter {
    static func counts(_ movies: [StatusSnapshot]) -> [ViewingStatus: Int] {
        Dictionary(grouping: movies, by: \.status).mapValues(\.count)
    }
}
