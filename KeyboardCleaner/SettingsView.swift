import SwiftUI

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @Binding var hasSeenOnboarding: Bool
    @State private var showPINSetup = false
    @State private var showDiagnostics = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "Settings", subtitle: nil) {
                Button {
                    showDiagnostics = true
                } label: {
                    Image(systemName: "waveform.path.ecg.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open diagnostics")
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }

            List {
                Section {
                    SettingsRow(
                        icon: "speaker.wave.2.fill",
                        iconTint: Design.accentEnd,
                        title: "Sound Feedback",
                        subtitle: "Play sounds when locking and unlocking"
                    ) {
                        Toggle("Sound Feedback", isOn: $cleaningState.soundEnabled)
                            .labelsHidden()
                            .accessibilityLabel("Sound Feedback")
                            .accessibilityHint("Play sounds when locking and unlocking")
                            .tint(Design.accentStart)
                    }

                    SettingsRow(
                        icon: "arrow.up.right.square.fill",
                        iconTint: Color(red: 0.60, green: 0.40, blue: 0.90),
                        title: "Launch at Login",
                        subtitle: "Start automatically when you log in"
                    ) {
                        Toggle("Launch at Login", isOn: Binding(
                            get: { cleaningState.isLaunchAtLoginEnabled },
                            set: { cleaningState.setLaunchAtLogin($0) }
                        ))
                        .labelsHidden()
                        .accessibilityLabel("Launch at Login")
                        .accessibilityHint("Start Keyboard Cleaner automatically when you log in")
                        .tint(Design.accentStart)
                    }

                    SettingsRow(
                        icon: "circle.grid.3x3.fill",
                        iconTint: Color(red: 0.30, green: 0.65, blue: 0.90),
                        title: "PIN Code",
                        subtitle: cleaningState.pinEnabled ? "Mouse-clickable numpad unlock" : "Unlock with a 4-digit PIN (no Touch ID needed)"
                    ) {
                        if cleaningState.pinEnabled {
                            HStack(spacing: 8) {
                                Button("Change") { showPINSetup = true }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Design.accentEnd)
                                    .accessibilityLabel("Change PIN code")
                                Button("Remove") { cleaningState.clearPin() }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 12, weight: .medium))
                                    .accessibilityLabel("Remove PIN code")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Button("Set PIN") { showPINSetup = true }
                                .buttonStyle(.plain)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Design.accentEnd)
                        }
                    }
                }

                Section("Cleaning Session") {
                    AutoUnlockPickerRow(cleaningState: cleaningState)
                    FullScreenCoverageRow(cleaningState: cleaningState)
                }

                Section("Presets") {
                    PresetRow(cleaningState: cleaningState)
                }

                Section("Advanced") {
                    SettingsRow(
                        icon: "arrow.counterclockwise",
                        iconTint: Color.secondary,
                        title: "Reset Onboarding",
                        subtitle: "Show the intro screens again on next launch"
                    ) {
                        Button("Reset") { hasSeenOnboarding = false }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .scrollContentBackground(.hidden)
            .background(AquaBackgroundView())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 660)
        .sheet(isPresented: $showPINSetup) {
            PINSetupSheet(cleaningState: cleaningState)
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsSheet(cleaningState: cleaningState)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Diagnostics Sheet

struct DiagnosticsSheet: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(
                title: "Diagnostics",
                subtitle: "Current state of permissions and app configuration."
            ) { EmptyView() }

            ZStack {
                AquaBackgroundView()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(cleaningState.diagnosticsItems.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 12) {
                                Text(item.label)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(statusColor(for: item.status))
                                        .frame(width: 6, height: 6)
                                        .accessibilityHidden(true)
                                    Text(item.value)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(statusColor(for: item.status))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(AppStrings.diagnosticsRow(item.label, item.value))

                            if index < cleaningState.diagnosticsItems.count - 1 {
                                Rectangle()
                                    .fill(.primary.opacity(0.07))
                                    .frame(height: 0.5)
                                    .padding(.leading, 16)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .background(GlassPanelBackground(cornerRadius: Design.cardRadius))
                    .padding(20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 420)
        .accessibilityElement(children: .contain)
    }

    private func statusColor(for status: DiagnosticStatus) -> Color {
        switch status {
        case .good:    return Design.accentStart
        case .bad:     return Design.errorRed
        case .neutral: return .secondary
        case .info:    return .primary
        }
    }
}

// MARK: - Help Sheet

struct HelpSheet: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(
                title: "Help",
                subtitle: "How to lock, unlock, and configure Keyboard Cleaner."
            ) { EmptyView() }

            ZStack {
                AquaBackgroundView()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        HelpCard(
                            icon: "lock.fill",
                            iconTint: Design.accentStart,
                            title: "Start a Cleaning Session",
                            items: [
                                "Click **Lock Keyboard** in the main window or choose it from the menu bar icon.",
                                "Press **⌃⌘L** (Control + Command + L) to lock from anywhere on your Mac.",
                                "Once locked, all keystrokes are blocked before they reach any other app."
                            ]
                        )

                        HelpCard(
                            icon: cleaningState.hasTouchID ? "touchid" : "circle.grid.3x3.fill",
                            iconTint: Design.accentEnd,
                            title: "Unlock Safely",
                            items: unlockHelpItems
                        )

                        HelpCard(
                            icon: "slider.horizontal.3",
                            iconTint: Color(red: 0.60, green: 0.40, blue: 0.90),
                            title: "Useful Settings",
                            items: [
                                "**Overlay** — choose a full-screen lock view or a compact floating panel.",
                                "**Auto-unlock** — end the session automatically after a set time.",
                                "**PIN Code** — set a mouse-only unlock path, useful as a Touch ID fallback."
                            ]
                        )

                        HelpCard(
                            icon: "wrench.and.screwdriver.fill",
                            iconTint: Color(red: 0.90, green: 0.55, blue: 0.20),
                            title: "Troubleshooting",
                            items: [
                                "If the keyboard won't lock, confirm Accessibility access is granted in **System Settings → Privacy**.",
                                "Open **Diagnostics** from Settings to inspect permission, event-tap, and unlock state.",
                                "If changes aren't detected, relaunch the app and run a quick lock test."
                            ]
                        )
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 580)
        .accessibilityElement(children: .contain)
    }

    private var unlockHelpItems: [String] {
        switch cleaningState.preferredUnlockMethod {
        case .touchID:
            if cleaningState.pinEnabled {
                return [
                    "**Touch ID** is the primary unlock path — place your finger on the sensor.",
                    "If Touch ID fails, tap **Use PIN** to switch to the mouse-clickable PIN pad.",
                    "The physical Touch ID key may trigger the macOS lock screen on some Macs."
                ]
            }
            return [
                "**Touch ID** is the primary unlock path — place your finger on the sensor.",
                "Set a **PIN** in Settings to have a mouse-only fallback if Touch ID isn't working.",
                "The physical Touch ID key may trigger the macOS lock screen on some Macs."
            ]
        case .pin:
            return [
                "Click digits on the **PIN pad** with your mouse — no keyboard needed.",
                "The PIN pad appears directly in the main window when the keyboard is locked.",
                "Set a PIN in **Settings** to change or remove it at any time."
            ]
        }
    }
}

// MARK: - Help Card

struct HelpCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconTint.opacity(0.15))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(iconTint)
                    )
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(iconTint.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                            .accessibilityHidden(true)
                        Text(LocalizedStringKey(item))
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .combine)

                    if index < items.count - 1 {
                        Rectangle()
                            .fill(.primary.opacity(0.07))
                            .frame(height: 0.5)
                            .padding(.leading, 29)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(GlassPanelBackground(cornerRadius: Design.cardRadius))
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Sheet Header

struct SheetHeaderView<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 10) {
                trailing
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Design.accentEnd)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }
}

// MARK: - PIN Setup Sheet

struct PINSetupSheet: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var step: SetupStep = .enter
    @State private var firstPIN = ""
    @State private var confirmPIN = ""
    @State private var mismatch = false

    enum SetupStep { case enter, confirm }

    var body: some View {
        ZStack {
            AquaBackgroundView()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text(step == .enter ? "Set a PIN Code" : "Confirm PIN")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(step == .enter
                             ? "Enter a 4-digit PIN — you'll use it to unlock with your mouse"
                             : mismatch ? "PINs don't match. Try again." : "Re-enter your PIN to confirm")
                            .font(.system(size: 13))
                            .foregroundStyle(mismatch ? Color.red.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }

                    PINPadView(
                        entry: step == .enter ? $firstPIN : $confirmPIN,
                        onComplete: advance,
                        onCancel: {
                            if step == .confirm {
                                withAnimation(.spring(response: 0.3)) {
                                    step = .enter
                                    confirmPIN = ""
                                    mismatch = false
                                }
                            } else {
                                dismiss()
                            }
                        }
                    )
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 26)
                .background(GlassPanelBackground(cornerRadius: 28))

                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 340, height: 420)
        .accessibilityElement(children: .contain)
    }

    private func advance() {
        if step == .enter {
            withAnimation(.spring(response: 0.3)) {
                step = .confirm
                mismatch = false
            }
        } else {
            if confirmPIN == firstPIN {
                cleaningState.setPin(firstPIN)
                dismiss()
            } else {
                mismatch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    confirmPIN = ""
                    mismatch = false
                }
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Control: View>: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String
    let control: Control

    init(
        icon: String,
        iconTint: Color,
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconTint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(LocalizedStringKey(title)) + Text(". ") + Text(LocalizedStringKey(subtitle)))

            Spacer()

            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
