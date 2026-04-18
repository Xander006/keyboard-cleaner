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
            Spacer().frame(height: 76)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Design.accentStart : Color.primary.opacity(0.18))
                        .frame(width: i == currentPage ? 20 : 7, height: 7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.bottom, 28)

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
                    .shadow(color: Design.accentStart.opacity(0.30), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .accessibilityLabel(currentPage < pages.count - 1 ? "Continue to next page" : "Get started")
            .keyboardShortcut(.defaultAction)

            Spacer().frame(height: 36)
        }
        .accessibilityElement(children: .contain)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 24) {
            GlassCircle(diameter: 110) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 34)
        .background(GlassPanelBackground(cornerRadius: 30))
    }
}
