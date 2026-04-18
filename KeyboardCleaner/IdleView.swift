import SwiftUI

// MARK: - Idle / Home Screen

struct IdleView: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 14) {
                GlassCircle(diameter: 88) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                }
                .accessibilityHidden(true)

                Text("A quiet way to lock the keyboard while you clean.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            .accessibilitySortPriority(4)

            InsetGroup(spacing: 0) {
                InfoCardRow(
                    icon: "hand.raised.slash",
                    iconTint: Design.accentStart,
                    title: "Blocks all keystrokes",
                    subtitle: "No accidental input while cleaning"
                )
                InsetDivider()
                InfoCardRow(
                    icon: cleaningState.hasTouchID ? "touchid" : "circle.grid.3x3.fill",
                    iconTint: Design.accentEnd,
                    title: cleaningState.hasTouchID ? "Touch ID to unlock" : "PIN to unlock",
                    subtitle: "A deliberate unlock path when you're done"
                )
                InsetDivider()
                InfoCardRow(
                    icon: "sparkles",
                    iconTint: Color(red: 0.60, green: 0.40, blue: 0.90),
                    title: "Wipe with confidence",
                    subtitle: "Designed for quick, low-friction cleaning sessions"
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 14)
            .accessibilitySortPriority(3)

            InsetGroup(spacing: 0) {
                AutoUnlockPickerRow(cleaningState: cleaningState)
            }
            .padding(.horizontal, 32)
            .accessibilitySortPriority(2)

            if !cleaningState.hasCompletedLockTest && (cleaningState.hasTouchID || cleaningState.pinEnabled) {
                QuickLockTestRow {
                    cleaningState.startCleaning()
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .accessibilitySortPriority(1.5)
            }

            // Fixed gap — a flexible Spacer() inside a ScrollView produces undefined heights
            Spacer().frame(height: 24)

            // No Touch ID + no PIN → must set up PIN first
            if !cleaningState.hasTouchID && !cleaningState.pinEnabled {
                NoPINWarningRow()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 10)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            Button {
                if !cleaningState.hasTouchID && !cleaningState.pinEnabled {
                    showSettings = true
                } else {
                    cleaningState.startCleaning()
                }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(!cleaningState.hasTouchID && !cleaningState.pinEnabled
                         ? "Set Up PIN to Continue"
                         : "Lock Keyboard")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AccentButtonBackground())
                .shadow(color: Design.accentStart.opacity(0.30), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .accessibilityLabel("Lock keyboard for cleaning")
            .accessibilityHint("Blocks all keyboard input. Unlock when done.")
            .accessibilitySortPriority(1)
            .keyboardShortcut(.defaultAction)

            Text(
                !cleaningState.hasTouchID && !cleaningState.pinEnabled
                    ? "No Touch ID detected — set a PIN to unlock"
                    : cleaningState.pinEnabled
                        ? "Touch ID or PIN to unlock  ·  ⌃⌘L to lock from anywhere"
                        : "Touch ID to unlock  ·  ⌃⌘L to lock from anywhere"
            )
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 10)
            .padding(.bottom, 36)
            .accessibilityLabel(
                !cleaningState.hasTouchID && !cleaningState.pinEnabled
                    ? "No Touch ID detected — set a PIN to unlock"
                    : cleaningState.pinEnabled
                        ? "Touch ID or PIN to unlock. Tip: press Control Command L to lock from anywhere."
                        : "Touch ID to unlock. Tip: press Control Command L to lock from anywhere."
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: cleaningState.pinEnabled)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: cleaningState.hasTouchID)
    }
}

// MARK: - Quick Lock Test Row

struct QuickLockTestRow: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Design.accentEnd)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Design.accentEnd.opacity(0.12)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Run a Quick Lock Test")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Try one short lock now so you know accessibility access is working before you start cleaning.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Button("Test") { action() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Design.accentEnd)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GlassCapsuleBackground())
                .accessibilityLabel("Run a quick lock test")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(GlassPanelBackground(cornerRadius: Design.cardRadius))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - No PIN Warning (shown on Macs without Touch ID when no PIN is set)

struct NoPINWarningRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("No Touch ID detected. Open Settings → PIN Code to set up a PIN.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            GlassPanelBackground(cornerRadius: Design.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Design.cardRadius)
                        .fill(Color.orange.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Design.cardRadius)
                        .stroke(Color.orange.opacity(0.16), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No Touch ID detected. Open Settings to set up a PIN.")
    }
}

// MARK: - Glass Segmented Control

struct GlassSegmentedControl<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.primary.opacity(0.10), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityLabel(label(option))
                .accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
            }
        }
        .padding(3)
        .background(GlassPanelBackground(cornerRadius: 11))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Auto-Unlock Picker Row

struct AutoUnlockPickerRow: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Auto-unlock")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Spacer()

            GlassSegmentedControl(
                options: AutoUnlockTimeout.allCases,
                label: \.label,
                selection: $cleaningState.autoUnlockTimeout
            )
            .frame(width: 210)
            .accessibilityLabel("Auto-unlock timeout")
            .accessibilityHint("Set a duration after which the keyboard unlocks automatically")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Full-Screen Coverage Row

struct FullScreenCoverageRow: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Display Target")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Spacer()

            GlassSegmentedControl(
                options: FullScreenCoverage.allCases,
                label: \.label,
                selection: $cleaningState.fullScreenCoverage
            )
            .frame(width: 210)
            .accessibilityLabel("Full-screen coverage")
            .accessibilityHint("Choose whether the full-screen overlay covers all displays or only the active display")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Info Card Row

struct InfoCardRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconTint)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(title)) + Text(". ") + Text(LocalizedStringKey(subtitle)))
    }
}

// MARK: - Preset Row

struct PresetRow: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(CleaningPreset.allCases.enumerated()), id: \.element.id) { index, preset in
                Button {
                    cleaningState.applyPreset(preset)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(preset.summary)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if cleaningState.currentPreset == preset {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Design.accentEnd)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(preset.title). \(preset.summary)")
                .accessibilityHint("Apply preset")

                if index < CleaningPreset.allCases.count - 1 {
                    InsetDivider()
                }
            }
        }
    }
}
