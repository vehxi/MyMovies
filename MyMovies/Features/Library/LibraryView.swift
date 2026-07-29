import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.system.rawValue
    @Query(sort: \Movie.updatedAt, order: .reverse) private var movies: [Movie]

    @State private var selection: LibraryFilter? = .all
    @State private var presentedSheet: MovieSheet?
    @State private var startupError: String?

    private let grid = [
        GridItem(.adaptive(minimum: 148, maximum: 210), spacing: 28)
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            content
                .navigationTitle(selectionTitle)
                .background(WindowTitleUpdater(title: selectionTitle))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            presentAddMovie()
                        } label: {
                            Label("Add Movie", systemImage: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .help("Add Movie")
                    }
                }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet.content {
            case .add:
                MovieEditorView()
            case .detail(let movie):
                MovieDetailView(movie: movie)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMovieRequested)) { _ in
            presentAddMovie()
        }
        .task {
            do {
                let language = AppLanguage(rawValue: appLanguageRawValue) ?? .system
                try InitialGenreSeeder.seedIfNeeded(context: modelContext, language: language)
            } catch {
                startupError = error.localizedDescription
            }
        }
        .alert("Could Not Prepare the Library", isPresented: startupErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(startupError ?? "")
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Label {
                sidebarLabel("All Movies", count: movies.count)
            } icon: {
                Image(systemName: "film.stack")
            }
            .tag(LibraryFilter.all)

            Label("Tier List", systemImage: "square.grid.3x3.square")
                .tag(LibraryFilter.tierList)

            Section("Status") {
                ForEach(ViewingStatus.allCases) { status in
                    Label {
                        HStack {
                            Text(status.titleKey)
                            Spacer()
                            Text(statusCount(status), format: .number)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: status.systemImage)
                    }
                    .tag(LibraryFilter.status(status))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("My Movies")
    }

    @ViewBuilder
    private var content: some View {
        if selection == .tierList {
            TierListView(movies: movies) { movie in
                presentedSheet = MovieSheet(content: .detail(movie))
            }
        } else if filteredMovies.isEmpty {
            ContentUnavailableView {
                Label(emptyTitle, systemImage: emptySystemImage)
            } description: {
                Text(emptyDescription)
            } actions: {
                Button("Add Movie") {
                    presentAddMovie()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: grid, alignment: .leading, spacing: 32) {
                    ForEach(filteredMovies) { movie in
                        MovieCardView(movie: movie) {
                            presentedSheet = MovieSheet(content: .detail(movie))
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private var filteredMovies: [Movie] {
        guard case .status(let status) = selection ?? .all else { return movies }
        return movies.filter { $0.status == status }
    }

    private var selectionTitle: String {
        switch selection ?? .all {
        case .all:
            AppLocalization.string("All Movies", locale: locale)
        case .tierList:
            AppLocalization.string("Tier List", locale: locale)
        case .status(let status):
            status.localizedTitle(locale: locale)
        }
    }

    private var emptyTitle: LocalizedStringKey {
        selection == .all ? "Your Library Is Empty" : "No Movies Here"
    }

    private var emptyDescription: LocalizedStringKey {
        selection == .all
            ? "Add your first movie to start a personal collection."
            : "Movies with this status will appear here."
    }

    private var emptySystemImage: String {
        selection?.systemImage ?? "film.stack"
    }

    private var startupErrorBinding: Binding<Bool> {
        Binding(
            get: { startupError != nil },
            set: { if !$0 { startupError = nil } }
        )
    }

    private func statusCount(_ status: ViewingStatus) -> Int {
        movies.lazy.filter { $0.status == status }.count
    }

    private func sidebarLabel(_ title: LocalizedStringKey, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(count, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func presentAddMovie() {
        presentedSheet = MovieSheet(content: .add)
    }
}
