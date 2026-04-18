import SwiftUI

// MARK: - Overlay Background (full-screen lock)

struct OverlayBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)

            Ellipse()
                .fill(Design.accentStart.opacity(0.06))
                .frame(width: 700, height: 500)
                .offset(x: -100 + sin(phase) * 35, y: -220 + cos(phase * 0.7) * 28)
                .blur(radius: 90)

            Ellipse()
                .fill(Color(red: 0.55, green: 0.38, blue: 0.88).opacity(0.04))
                .frame(width: 600, height: 550)
                .offset(x: 160 + cos(phase * 0.8) * 30, y: 160 + sin(phase * 1.1) * 25)
                .blur(radius: 100)
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

// MARK: - Overlay View (full-screen lock shown on every display)

struct OverlayView: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @State private var pulseAnimation = false
    @State private var errorShake = false
    @State private var lockClosed = false

    var body: some View {
        ZStack {
            OverlayBackgroundView()

            // GeometryReader centers content when it fits; ScrollView handles small screens
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 32)

                        ZStack {
                            PulseRings(animating: pulseAnimation, count: 3,
                                       baseSize: 100, step: 28, maxOpacity: 0.05)
                            GlassCircle(diameter: 96) {
                                LockIconView(closed: lockClosed, size: 36)
                            }
                        }
                        .onAppear {
                            pulseAnimation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { lockClosed = true }
                        }
                        .onChange(of: cleaningState.authState) { _, new in
                            if new == .success {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { lockClosed = false }
                            }
                        }
                        .accessibilityLabel("Keyboard is locked")
                        .padding(.bottom, 20)

                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                HStack(alignment: .lastTextBaseline, spacing: 5) {
                                    Text("Keyboard")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Text("Locked")
                                        .font(.system(size: 38, weight: .black))
                                        .tracking(-0.8)
                                        .foregroundStyle(Design.accentGradient)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Keyboard Locked")
                                .accessibilityAddTraits(.isHeader)

                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .medium))
                                        .accessibilityHidden(true)
                                    Text("Wipe with confidence")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(GlassCapsuleBackground())
                            }

                            if cleaningState.autoUnlockTimeout != .never {
                                CountdownRingView(cleaningState: cleaningState)
                            } else {
                                OverlayElapsedView(cleaningState: cleaningState)
                            }
                        }
                        .padding(.horizontal, 34)
                        .padding(.vertical, 24)
                        .background(GlassPanelBackground(cornerRadius: 30))
                        .padding(.horizontal, 32)
                        .accessibilitySortPriority(2)

                        Spacer(minLength: 24)

                        VStack(spacing: 14) {
                            UnlockButton(cleaningState: cleaningState, onFailure: triggerErrorShake)
                                .offset(x: errorShake ? -8 : 0)
                                .animation(
                                    errorShake
                                        ? .easeInOut(duration: Timing.errorShakeUnit)
                                            .repeatCount(Timing.errorShakeRepeat, autoreverses: true)
                                        : .default,
                                    value: errorShake
                                )

                            if cleaningState.hasTouchID {
                                TouchIDKeyNote()
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                        .background(GlassPanelBackground(cornerRadius: 28))
                        .padding(.horizontal, 28)
                        .accessibilitySortPriority(1)

                        Spacer(minLength: 32)
                    }
                    // minHeight ensures Spacers expand to center content when it fits
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .ignoresSafeArea()
    }

    private func triggerErrorShake() {
        errorShake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { errorShake = false }
    }
}
