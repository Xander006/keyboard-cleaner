import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject private var cleaningState: CleaningStateManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSettings = false
    @State private var showDiagnostics = false
    @State private var showHelp = false

    var body: some View {
        ZStack {
            AquaBackgroundView()

            if !cleaningState.isAccessibilityAuthorized {
                SceneScrollView {
                    AccessibilityPermissionView(cleaningState: cleaningState)
                }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 1.04).combined(with: .opacity)
                    ))
            } else if !hasSeenOnboarding {
                SceneScrollView {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 1.04).combined(with: .opacity)
                    ))
            } else if cleaningState.isLocked {
                LockedView(cleaningState: cleaningState)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 1.04).combined(with: .opacity)
                    ))
            } else {
                SceneScrollView {
                    IdleView(cleaningState: cleaningState, showSettings: $showSettings)
                }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 1.04).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: cleaningState.isAccessibilityAuthorized)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: cleaningState.isLocked)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: hasSeenOnboarding)
        .safeAreaInset(edge: .top, spacing: 0) {
            if cleaningState.isAccessibilityAuthorized && hasSeenOnboarding && !cleaningState.isLocked {
                WindowAccessoryBar(
                    openSettings: { showSettings = true },
                    openHelp: { showHelp = true }
                )
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(cleaningState: cleaningState, hasSeenOnboarding: $hasSeenOnboarding)
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsSheet(cleaningState: cleaningState)
        }
        .sheet(isPresented: $showHelp) {
            HelpSheet(cleaningState: cleaningState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequested)) { _ in
            showSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDiagnosticsRequested)) { _ in
            showDiagnostics = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelpRequested)) { _ in
            showHelp = true
        }
        .alert(
            "Unable to Lock Keyboard",
            isPresented: Binding(
                get: { cleaningState.lockFailureMessage != nil },
                set: { if !$0 { cleaningState.lockFailureMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cleaningState.lockFailureMessage ?? "")
        }
    }
}

// MARK: - Scene Scroll View

private struct SceneScrollView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Accessibility Permission Gate

private struct AccessibilityPermissionView: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @State private var didCheck = false
    @State private var checkFailed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 88)

            VStack(spacing: 24) {
                GlassCircle(diameter: 96) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Accessibility Access Required")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Keyboard Cleaner needs accessibility permission to intercept keyboard input before it reaches other apps.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 22)
            .accessibilitySortPriority(3)

            InsetGroup(spacing: 0) {
                PermissionStepRow(number: "1", text: "Open System Settings")
                PermissionStepRow(number: "2", text: "Privacy & Security → Accessibility")
                PermissionStepRow(number: "3", text: "Toggle on Keyboard Cleaner — or tap + to add it if it's not listed")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 18)
            .accessibilitySortPriority(2)

            InsetGroup(spacing: 0) {
                Button {
                    cleaningState.requestAccessibilityPermission()
                    didCheck = false
                    checkFailed = false
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "gear")
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text("Open System Settings")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AccentButtonBackground())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .accessibilityLabel("Open System Settings to grant accessibility access")
                .keyboardShortcut(.defaultAction)

                Button {
                    didCheck = true
                    let granted = cleaningState.recheckAccessibility()
                    checkFailed = !granted
                } label: {
                    Text("I've Granted Access")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(checkFailed ? Color.red.opacity(0.8) : Design.accentEnd)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, checkFailed ? 8 : 16)
                .accessibilityLabel("Recheck accessibility permission")

                if checkFailed {
                    VStack(spacing: 8) {
                        Text("Permission not detected yet.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Button {
                            cleaningState.relaunch()
                        } label: {
                            Text("Relaunch App")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(GlassCapsuleBackground())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, 32)
            .accessibilitySortPriority(1)

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: checkFailed)
    }
}

private struct PermissionStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Design.accentStart.opacity(0.14))
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Design.accentStart)
            }
            Text(LocalizedStringKey(text))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GlassPanelBackground(cornerRadius: Design.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppStrings.step(number, text))
    }
}

// MARK: - Window Accessory Bar

private struct WindowAccessoryBar: View {
    let openSettings: () -> Void
    let openHelp: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Design.accentGradient.opacity(0.16))
                        .frame(width: 28, height: 28)
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Design.accentGradient)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Keyboard Cleaner")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Ready to lock")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: openHelp) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.thinMaterial))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open help")
                .accessibilityHint("Open help and usage guidance")
                .keyboardShortcut("/", modifiers: [.command, .shift])

                Button(action: openSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.thinMaterial))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
                .accessibilityHint("Open cleaning, unlock, and menu bar preferences")
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GlassPanelBackground(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

// MARK: - Aqua Background (main window — adapts to light / dark mode)

struct AquaBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base: near-white in light, deep graphite in dark
            LinearGradient(
                colors: colorScheme == .light
                    ? [Color(red: 0.97, green: 0.97, blue: 0.975),
                       Color(red: 0.92, green: 0.925, blue: 0.940)]
                    : [Color(red: 0.07, green: 0.07, blue: 0.08),
                       Color(red: 0.11, green: 0.11, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Blob 1 — soft sage/mint
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        (colorScheme == .light
                            ? Color(red: 0.30, green: 0.88, blue: 0.68)
                            : Color(red: 0.18, green: 0.74, blue: 0.62))
                        .opacity(colorScheme == .light ? 0.16 : 0.20),
                        .clear
                    ],
                    center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 380, height: 280)
                .offset(x: -50 + sin(phase) * 20, y: -80 + cos(phase * 0.7) * 15)
                .blur(radius: 65)

            // Blob 2 — soft lavender/violet
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        (colorScheme == .light
                            ? Color(red: 0.62, green: 0.48, blue: 0.92)
                            : Color(red: 0.42, green: 0.28, blue: 0.86))
                        .opacity(colorScheme == .light ? 0.09 : 0.13),
                        .clear
                    ],
                    center: .center, startRadius: 0, endRadius: 170))
                .frame(width: 300, height: 310)
                .offset(x: 85 + cos(phase * 0.8) * 24, y: 100 + sin(phase * 1.1) * 18)
                .blur(radius: 70)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else {
                phase = 0
                return
            }
            withAnimation(.linear(duration: Timing.background).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
