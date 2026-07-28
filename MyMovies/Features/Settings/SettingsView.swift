import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            GenreSettingsView()
                .tabItem {
                    Label("Genres", systemImage: "tag")
                }
        }
        .frame(width: 560, height: 440)
    }
}
