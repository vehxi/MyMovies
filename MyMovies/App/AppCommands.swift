import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add Movie") {
                NotificationCenter.default.post(name: .newMovieRequested, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
