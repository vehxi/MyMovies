import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MovieEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Genre.name) private var genres: [Genre]
    @Query private var allMovies: [Movie]

    private let movie: Movie?

    @State private var title: String
    @State private var yearText: String
    @State private var status: ViewingStatus
    @State private var isFavorite: Bool
    @State private var rating: Int?
    @State private var synopsis: String
    @State private var selectedGenreIDs: Set<UUID>
    @State private var pendingCoverData: Data?
    @State private var removesExistingCover = false

    @State private var showsFileImporter = false
    @State private var showsDuplicateWarning = false
    @State private var pendingStatus: ViewingStatus?
    @State private var showsRatingRemovalWarning = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(movie: Movie? = nil) {
        self.movie = movie
        _title = State(initialValue: movie?.title ?? "")
        _yearText = State(initialValue: movie?.releaseYear.map(String.init) ?? "")
        _status = State(initialValue: movie?.status ?? .wantToWatch)
        _isFavorite = State(initialValue: movie?.isFavorite ?? false)
        _rating = State(initialValue: movie?.rating)
        _synopsis = State(initialValue: movie?.synopsis ?? "")
        _selectedGenreIDs = State(initialValue: Set(movie?.genres.map(\.id) ?? []))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    coverSection
                    fields
                }
                .padding(24)
            }
            Divider()
            footer
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 560, idealHeight: 640)
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: handleFileImport
        )
        .alert("Possible Duplicate", isPresented: $showsDuplicateWarning) {
            Button("Keep Editing", role: .cancel) {}
            Button("Save Anyway") {
                Task { await save() }
            }
        } message: {
            Text("A movie with the same title and year already exists.")
        }
        .alert("Remove Rating?", isPresented: $showsRatingRemovalWarning) {
            Button("Cancel", role: .cancel) {
                pendingStatus = nil
            }
            Button("Change Status", role: .destructive) {
                if let pendingStatus {
                    status = pendingStatus
                    rating = nil
                }
                pendingStatus = nil
            }
        } message: {
            Text("Ratings are only available for watched movies. Changing the status will clear this rating.")
        }
        .alert("Could Not Save Movie", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            if movie == nil {
                Text("Add Movie")
                    .font(.title2.weight(.semibold))
            } else {
                Text("Edit Movie")
                    .font(.title2.weight(.semibold))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var coverSection: some View {
        VStack(spacing: 12) {
            coverPreview
                .frame(width: 210, height: 315)
                .dropDestination(for: URL.self) { urls, _ in
                    guard let url = urls.first else { return false }
                    Task { await loadImage(from: url) }
                    return true
                }
                .accessibilityLabel("Movie Cover")
                .accessibilityHint("Drop an image file here")

            HStack {
                Button("Choose…") {
                    showsFileImporter = true
                }
                Button("Paste") {
                    pasteImage()
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }

            if hasCover {
                Button("Remove Cover", role: .destructive) {
                    pendingCoverData = nil
                    removesExistingCover = true
                }
                .buttonStyle(.plain)
            }

            Text("Choose, drop, or paste an image.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var coverPreview: some View {
        if let data = pendingCoverData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.primary.opacity(0.08))
                }
        } else if !removesExistingCover {
            PosterArtwork(title: title, filename: movie?.coverFilename)
        } else {
            PosterArtwork(title: title, filename: nil)
        }
    }

    private var fields: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField(
                        "",
                        text: $title,
                        prompt: Text("Enter movie title")
                    )
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel("Movie Title")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Release Year")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField(
                        "",
                        text: $yearText,
                        prompt: Text("YYYY")
                    )
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                        .monospacedDigit()
                        .frame(width: 120, alignment: .leading)
                        .accessibilityHint("Enter a four digit year or leave blank")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Status", selection: statusBinding) {
                    ForEach(ViewingStatus.allCases) { value in
                        Label(value.titleKey, systemImage: value.systemImage)
                            .tag(value)
                    }
                }

                Toggle(isOn: $isFavorite) {
                    Label(
                        "Favorite",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                }

                LabeledContent("Rating") {
                    StarRating(
                        rating: $rating,
                        isEnabled: status.allowsRating
                    )
                }

                if !status.allowsRating {
                    Text("Rating becomes available after the movie is watched.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Genres") {
                if genres.isEmpty {
                    Text("Add genres in Settings.")
                        .foregroundStyle(.secondary)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(genres) { genre in
                            Toggle(
                                genre.name,
                                isOn: Binding(
                                    get: { selectedGenreIDs.contains(genre.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedGenreIDs.insert(genre.id)
                                        } else {
                                            selectedGenreIDs.remove(genre.id)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }

            Section("Description") {
                TextField(
                    "",
                    text: $synopsis,
                    prompt: Text("Add notes or a synopsis"),
                    axis: .vertical
                )
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5...10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button {
                attemptSave()
            } label: {
                if movie == nil {
                    Text("Add Movie")
                } else {
                    Text("Save")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!isValid || isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var hasCover: Bool {
        pendingCoverData != nil || (!removesExistingCover && movie?.coverFilename != nil)
    }

    private var parsedYear: Int? {
        let trimmed = yearText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    private var isValid: Bool {
        !TextNormalizer.displayName(title).isEmpty
            && (yearText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (parsedYear.map { (1000...9999).contains($0) } ?? false))
    }

    private var statusBinding: Binding<ViewingStatus> {
        Binding(
            get: { status },
            set: { newStatus in
                if rating != nil, !newStatus.allowsRating {
                    pendingStatus = newStatus
                    showsRatingRemovalWarning = true
                } else {
                    status = newStatus
                }
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func attemptSave() {
        let candidates = allMovies.map {
            DuplicateCandidate(id: $0.id, title: $0.title, releaseYear: $0.releaseYear)
        }
        if DuplicateDetector.containsDuplicate(
            title: title,
            releaseYear: parsedYear,
            excluding: movie?.id,
            in: candidates
        ) {
            showsDuplicateWarning = true
        } else {
            Task { await save() }
        }
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        defer { isSaving = false }

        let previousFilename = movie?.coverFilename
        var newlyWrittenFilename: String?

        do {
            let coverFilename: String?
            if let pendingCoverData {
                newlyWrittenFilename = try await CoverStore.shared.write(pendingCoverData)
                coverFilename = newlyWrittenFilename
            } else if removesExistingCover {
                coverFilename = nil
            } else {
                coverFilename = previousFilename
            }

            let selectedGenres = genres.filter { selectedGenreIDs.contains($0.id) }
            if let movie {
                movie.update(
                    title: title,
                    releaseYear: parsedYear,
                    status: status,
                    isFavorite: isFavorite,
                    rating: rating,
                    synopsis: synopsis,
                    coverFilename: coverFilename,
                    genres: selectedGenres
                )
            } else {
                modelContext.insert(
                    Movie(
                        title: title,
                        releaseYear: parsedYear,
                        status: status,
                        isFavorite: isFavorite,
                        rating: rating,
                        synopsis: synopsis,
                        coverFilename: coverFilename,
                        genres: selectedGenres
                    )
                )
            }
            try modelContext.save()

            if previousFilename != coverFilename {
                try? await CoverStore.shared.delete(filename: previousFilename)
            }
            dismiss()
        } catch {
            modelContext.rollback()
            try? await CoverStore.shared.delete(filename: newlyWrittenFilename)
            errorMessage = error.localizedDescription
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task { await loadImage(from: url) }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadImage(from url: URL) async {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            pendingCoverData = try await Task.detached {
                try ImageProcessor.normalizedJPEGData(from: data)
            }.value
            removesExistingCover = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pasteImage() {
        guard let image = NSImage(pasteboard: NSPasteboard.general),
              let data = image.tiffRepresentation
        else {
            errorMessage = String(localized: "The clipboard does not contain an image.")
            return
        }

        Task { @MainActor in
            do {
                pendingCoverData = try await Task.detached {
                    try ImageProcessor.normalizedJPEGData(from: data)
                }.value
                removesExistingCover = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
