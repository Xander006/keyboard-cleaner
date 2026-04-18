import SwiftUI

// MARK: - Animation Constants

enum Timing {
    static let pulse: Double = 2.8
    static let background: Double = 20.0
    static let errorShakeUnit: Double = 0.06
    static let errorShakeRepeat = 6
}

// MARK: - Design Tokens

enum Design {
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 16

    // Fresh mint → cool teal CTA gradient
    static let accentStart = Color(red: 0.22, green: 0.80, blue: 0.64)
    static let accentEnd   = Color(red: 0.08, green: 0.60, blue: 0.80)
    static let errorRed    = Color(red: 0.90, green: 0.28, blue: 0.28)

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentStart, accentEnd],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Circle

/// Liquid-glass orb — uses thin material for maximum transparency.
/// Specular and rim highlights simulate light from top-left.
struct GlassCircle<Content: View>: View {
    let diameter: CGFloat
    let content: Content

    init(diameter: CGFloat, @ViewBuilder content: () -> Content) {
        self.diameter = diameter
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Depth shadow
            Circle()
                .fill(Color.black.opacity(0.09))
                .frame(width: diameter, height: diameter)
                .blur(radius: diameter * 0.22)
                .offset(y: diameter * 0.08)

            Circle()
                .fill(.thinMaterial)
                .frame(width: diameter, height: diameter)
                // Primary top-left specular catch-light
                .overlay(
                    Circle()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.04), .clear],
                            startPoint: UnitPoint(x: 0.14, y: 0.02),
                            endPoint: UnitPoint(x: 0.66, y: 0.56)
                        ))
                )
                // Rim — bright arc top-left, fades bottom-right
                .overlay(
                    Circle()
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.02), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 0.75)
                )
                .shadow(color: .black.opacity(0.09), radius: diameter * 0.16, y: diameter * 0.05)

            content
        }
    }
}

// MARK: - Accent Button Background (primary CTA)

struct AccentButtonBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Design.buttonRadius)
            .fill(Design.accentGradient)
            // Subtle inner top highlight for glass-like depth
            .overlay(
                RoundedRectangle(cornerRadius: Design.buttonRadius)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .top, endPoint: .center
                    ))
            )
    }
}

// MARK: - Glass Panel Background

struct GlassPanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient(
                        colors: colorScheme == .dark
                            ? [.white.opacity(0.16), .white.opacity(0.04), .clear]
                            : [.white.opacity(0.14), .white.opacity(0.02), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white.opacity(0.20), .white.opacity(0.04)]
                                : [.white.opacity(0.34), .primary.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.22 : 0.06),
                radius: colorScheme == .dark ? 22 : 18,
                y: colorScheme == .dark ? 10 : 8
            )
    }
}

// MARK: - Glass Capsule Background

struct GlassCapsuleBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .fill(LinearGradient(
                        colors: colorScheme == .dark ? [.white.opacity(0.14), .clear] : [.white.opacity(0.12), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white.opacity(0.18), .white.opacity(0.05)]
                                : [.white.opacity(0.28), .primary.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.04), radius: 10, y: 4)
    }
}

// MARK: - Inset Group + Divider

struct InsetGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .background(GlassPanelBackground(cornerRadius: Design.cardRadius))
    }
}

struct InsetDivider: View {
    var body: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 62)
            .accessibilityHidden(true)
    }
}

// MARK: - Animation Helper

extension Animation {
    func repeatWhile(_ condition: Bool, autoreverses: Bool = true) -> Animation {
        condition ? repeatForever(autoreverses: autoreverses) : self
    }
}
