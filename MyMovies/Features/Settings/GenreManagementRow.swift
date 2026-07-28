import SwiftUI

struct GenreManagementRow: View {
    let genre: Genre
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var name: String

    init(
        genre: Genre,
        onRename: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.genre = genre
        self.onRename = onRename
        self.onDelete = onDelete
        _name = State(initialValue: genre.name)
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Genre Name", text: $name)
                .onSubmit {
                    onRename(name)
                }

            Text(genre.movies.count, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 28, alignment: .trailing)
                .help("Number of Movies")

            Button {
                onRename(name)
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.borderless)
            .disabled(
                TextNormalizer.displayName(name).isEmpty
                    || TextNormalizer.displayName(name) == genre.name
            )
            .accessibilityLabel("Save Genre Name")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete Genre")
        }
        .padding(.vertical, 3)
    }
}
