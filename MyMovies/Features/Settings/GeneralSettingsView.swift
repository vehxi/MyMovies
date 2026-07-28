import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section("Language") {
                Picker("Application Language", selection: $appLanguageRawValue) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.titleKey)
                            .tag(language.rawValue)
                    }
                }

                Text("The app content changes immediately. Some system menu items may require reopening the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Storage") {
                LabeledContent("Database") {
                    Text("Application Support")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Covers") {
                    Text("Application Support/My Movies/Covers")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Text("All information stays on this Mac. iCloud and online services are not used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
