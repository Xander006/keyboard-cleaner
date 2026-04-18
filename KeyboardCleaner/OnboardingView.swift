import SwiftUI

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject private var cleaningState: CleaningStateManager
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private var pages: [(icon: String, title: String, subtitle: String)] {
        let unlockPage: (icon: String, title: String, subtitle: String)
        switch cleaningState.preferredUnlockMethod {
        case .touchID:
            unlockPage = (
                icon: "touchid",
                title: cleaningState.pinEnabled ? "Touch ID, With PIN Backup" : "Touch ID to Unlock",
                subtitle: cleaningState.pinEnabled
                    ? "Touch ID is the primary unlock path, and your PIN stays available as a deliberate fallback."
                    : "When you're done cleaning, Touch ID unlocks everything instantly."
            )
        case .pin:
            unlockPage = (
                icon: "circle.grid.3x3.fill",
                title: "PIN to Unlock",
                subtitle: "No Touch ID? No problem — unlock using the on-screen PIN pad with your mouse, no keyboard needed."
            )
        }

        return [
            (
                icon: "keyboard",
                title: "Meet Keyboard Cleaner",
                subtitle: "Lock your keyboard and clean every key safely — no accidental input, no worries."
            ),
            (
                icon: "lock.shield.fill",
                title: "One Tap, Fully Locked",
                subtitle: "Every keystroke is blocked the moment you tap Lock. Wipe as hard as you like."
            ),
            unlockPage,
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                ForEach(pages.indices, id: \.self) { i in
                    if i == currentPage {
                        OnboardingPage(
                            icon: pages[i].icon,
                            title: pages[i].title,
                            subtitle: pages[i].subtitle
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
            }
            .animation(.spring(response: 0.48, dampingFraction: 0.82), value: currentPage)
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(spacing: 20) {
                // Page indicator dots
                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? AnyShapeStyle(Design.accentGradient)
                                  : AnyShapeStyle(Color.primary.opacity(0.15)))
                            .frame(width: i == currentPage ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .accessibilityHidden(true)

                Button {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AccentButtonBackground())
                        .shadow(color: Design.accentStart.opacity(0.28), radius: 14, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(currentPage < pages.count - 1 ? "Continue to next page" : "Get started")
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .accessibilityElement(children: .contain)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 32) {
            // Gradient orb with white symbol — matches app icon language
            ZStack {
                // Soft glow behind orb
                Circle()
                    .fill(Design.accentStart.opacity(0.18))
                    .frame(width: 140, height: 140)
                    .blur(radius: 28)

                Circle()
                    .fill(Design.accentGradient)
                    .frame(width: 108, height: 108)
                    .overlay(
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.22), .clear],
                                startPoint: UnitPoint(x: 0.2, y: 0.1),
                                endPoint: UnitPoint(x: 0.7, y: 0.6)
                            ))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.45), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    )
                    .shadow(color: Design.accentEnd.opacity(0.38), radius: 22, y: 8)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 32)
    }
}
