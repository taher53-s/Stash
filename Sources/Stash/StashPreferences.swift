// Luminous Desktop native-product style: compact graphite surfaces, one cyan active cue, and macOS-native controls.
import AppKit
import SwiftUI

enum ShareDestination: String, CaseIterable, Identifiable {
    case airDrop = "AirDrop"
    case messages = "Messages"
    case mail = "Mail"
    case systemSheet = "System Share Sheet"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .airDrop: return "airplayaudio"
        case .messages: return "message.fill"
        case .mail: return "envelope.fill"
        case .systemSheet: return "square.and.arrow.up"
        }
    }
}

enum StashTheme {
    static let glow = Color(red: 0.62, green: 0.96, blue: 1.0)

    static func copyPath(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }
}

struct StashSettingsView: View {
    @AppStorage("stash.defaultShareDestination") private var defaultShareDestination = ShareDestination.airDrop.rawValue
    @AppStorage("stash.autoClearEnabled") private var autoClearEnabled = true
    @AppStorage("stash.autoClearHours") private var autoClearHours = 24
    @AppStorage("stash.showItemCount") private var showItemCount = true
    @AppStorage("stash.keepShelvesOnTop") private var keepShelvesOnTop = true

    var body: some View {
        Form {
            Section("Shelf defaults") {
                Toggle("Keep shelves above other windows", isOn: $keepShelvesOnTop)
                Toggle("Show item count in the menu bar", isOn: $showItemCount)
                Toggle("Recycle inactive shelves automatically", isOn: $autoClearEnabled)
                if autoClearEnabled {
                    Picker("Clear after", selection: $autoClearHours) {
                        Text("1 hour").tag(1)
                        Text("24 hours").tag(24)
                        Text("7 days").tag(168)
                    }
                    Text("The timer restarts whenever you add an item to a shelf.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Quick share") {
                Picker("Default destination", selection: $defaultShareDestination) {
                    ForEach(ShareDestination.allCases) { destination in
                        Label(destination.rawValue, systemImage: destination.symbol).tag(destination.rawValue)
                    }
                }
                Text("Share actions use macOS sharing services, so files stay local until you choose a destination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy and permissions") {
                LabeledContent("File access", value: "Only files you drop into Stash")
                LabeledContent("Sharing", value: "User-initiated through macOS")
                LabeledContent("Network service", value: "None")
                Text("Stash does not upload, index, or duplicate the contents of your shelf. Accessibility access is used only to recognize the drag-and-shake gesture.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About Stash") {
                LabeledContent("Privacy", value: "Local-only")
                LabeledContent("Compatibility", value: "macOS 14 or later")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .padding()
    }
}
