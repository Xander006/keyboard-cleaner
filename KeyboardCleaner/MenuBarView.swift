import SwiftUI

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var cleaningState: CleaningStateManager

    var body: some View {
        if cleaningState.isLocked {
            Menu("Locked") {
                Text(AppStrings.lockedFor(cleaningState.elapsedTimeString))
                if let remaining = cleaningState.remainingTimeString {
                    Text(AppStrings.autoUnlockIn(remaining))
                }
            }
            Button("Unlock Keyboard…") { cleaningState.authenticateToUnlock { _ in } }
        } else {
            Button("Lock Keyboard") { cleaningState.startCleaning() }
        }

        Menu("Presets") {
            if let preset = cleaningState.currentPreset {
                Text(AppStrings.preset(preset.title))
            }
            ForEach(CleaningPreset.allCases) { preset in
                Button(preset.title) { cleaningState.applyPreset(preset) }
            }
        }

        Divider()

        Menu("Open") {
            Button("Settings…")    { showWindow(then: .openSettingsRequested) }
            Button("Diagnostics…") { showWindow(then: .openDiagnosticsRequested) }
            Button("Help…")        { showWindow(then: .openHelpRequested) }
        }

        Divider()
        Button("Quit Keyboard Cleaner") { NSApplication.shared.terminate(nil) }
    }

    private func showWindow(then name: Notification.Name? = nil) {
        if let name {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}
