import SwiftData
import SwiftUI

struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let movie: Movie

    @State private var showsEditor = false
    @State private var showsDeleteConfirmation = false
    @State private var pendingStatus: ViewingStatus?
    @State private var showsRatingRemovalWarning = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                HStack(alignment: .top, spacing: 28) {
                    PosterArtwork(title: movie.title, filename: movie.coverFilename)
                        .frame(width: 240, height: 360)
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)

                    details
                }
                .padding(28)
            }

            Divider()
            actions
        }
        .frame(minWidth: 720, idealWidth: 780, minHeight: 510, idealHeight: 580)
        .sheet(isPresented: $showsEditor) {
            MovieEditorView(movie: movie)
        }
        .alert("Delete Movie?", isPresented: $showsDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteMovie() }
            }
        } message: {
            Text("The movie and its local cover copy will be permanently deleted.")
        }
        .alert("Remove Rating?", isPresented: $showsRatingRemovalWarning) {
            Button("Cancel", role: .cancel) {
                pendingStatus = nil
            }
            Button("Change Status", role: .destructive) {
                applyPendingStatus()
            }
        } message: {
            Text("Ratings are only available for watched or favorite movies. Changing the status will clear this rating.")
        }
        .alert("Could Not Complete the Action", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.largeTitle.weight(.semibold))
                    .textSelection(.enabled)

                if let year = movie.releaseYear {
                    Text(year, format: .number.grouping(.never))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Status", selection: statusBinding) {
                ForEach(ViewingStatus.allCases) { status in
                    Label(status.titleKey, systemImage: status.systemImage)
                        .tag(status)
                }
            }
            .frame(maxWidth: 260)

            LabeledContent("Rating") {
                StarRating(
                    rating: ratingBinding,
                    isEnabled: movie.status.allowsRating
                )
            }

            if !movie.genres.isEmpty {
                LabeledContent("Genres") {
                    Text(movie.genres.sorted { $0.name < $1.name }.map(\.name).joined(separator: ", "))
                        .multilineTextAlignment(.trailing)
                }
            }

            if !movie.synopsis.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.headline)
                    Text(movie.synopsis)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text("Added \(movie.createdAt, format: .dateTime.day().month().year())")
                Text("Updated \(movie.updatedAt, format: .dateTime.day().month().year())")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        HStack {
            Button("Delete", role: .destructive) {
                showsDeleteConfirmation = true
            }
            Spacer()
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            Button("Edit") {
                showsEditor = true
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var statusBinding: Binding<ViewingStatus> {
        Binding(
            get: { movie.status },
            set: { newStatus in
                if movie.rating != nil, !newStatus.allowsRating {
                    pendingStatus = newStatus
                    showsRatingRemovalWarning = true
                } else {
                    movie.status = newStatus
                    saveChanges()
                }
            }
        )
    }

    private var ratingBinding: Binding<Int?> {
        Binding(
            get: { movie.rating },
            set: { newValue in
                movie.rating = RatingRules.validated(newValue, for: movie.status)
                movie.updatedAt = .now
                saveChanges()
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func applyPendingStatus() {
        guard let pendingStatus else { return }
        movie.status = pendingStatus
        movie.rating = nil
        self.pendingStatus = nil
        saveChanges()
    }

    private func saveChanges() {
        movie.updatedAt = .now
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteMovie() async {
        let filename = movie.coverFilename
        do {
            modelContext.delete(movie)
            try modelContext.save()
            try await CoverStore.shared.delete(filename: filename)
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
