import SwiftUI

// MARK: - Locked View

struct LockedView: View {
    @ObservedObject var cleaningState: CleaningStateManager
    @State private var pulseAnimation = false
    @State private var errorShake = false
    @State private var lockClosed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                ZStack {
                    PulseRings(animating: pulseAnimation, count: 3,
                               baseSize: 130, step: 34, maxOpacity: 0.06)
                    GlassCircle(diameter: 114) {
                        LockIconView(closed: lockClosed, size: 42)
                    }
                }
                .offset(x: errorShake ? -8 : 0)
                .animation(
                    errorShake
                        ? .easeInOut(duration: Timing.errorShakeUnit)
                            .repeatCount(Timing.errorShakeRepeat, autoreverses: true)
                        : .default,
                    value: errorShake
                )
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

                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("Keyboard")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Locked")
                            .font(.system(size: 26, weight: .black))
                            .tracking(-0.6)
                            .foregroundStyle(Design.accentGradient)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Keyboard Locked")
                    .accessibilityAddTraits(.isHeader)

                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .medium))
                            .accessibilityHidden(true)
                        Text("Wipe with confidence")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(GlassCapsuleBackground())

                    Text(statusMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                        .animation(.easeInOut(duration: 0.2), value: cleaningState.authState)

                    if cleaningState.authState == .idle || cleaningState.authState == .failed {
                        if cleaningState.autoUnlockTimeout != .never {
                            CountdownRingView(cleaningState: cleaningState)
                                .padding(.top, 4)
                        } else {
                            OverlayElapsedView(cleaningState: cleaningState)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 22)
                .background(GlassPanelBackground(cornerRadius: 24))
                .padding(.horizontal, 44)
                .accessibilitySortPriority(2)
            }

            Spacer()

            UnlockButton(cleaningState: cleaningState, onFailure: triggerErrorShake)
                .accessibilitySortPriority(1)

            if cleaningState.hasTouchID {
                TouchIDKeyNote()
                    .padding(.top, 12)
                    .accessibilitySortPriority(0.5)
            }
            Spacer().frame(height: 44)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusMessage: String {
        switch cleaningState.authState {
        case .idle:           return String(localized: "All keystrokes are blocked.\nClean your keyboard freely.")
        case .authenticating: return cleaningState.hasTouchID ? String(localized: "Place your finger on Touch ID…") : String(localized: "Verifying…")
        case .failed:         return cleaningState.hasTouchID ? String(localized: "Touch ID failed. Try again.") : String(localized: "Authentication failed. Try again.")
        case .success:        return String(localized: "Unlocked successfully!")
        }
    }

    private func triggerErrorShake() {
        errorShake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { errorShake = false }
    }
}

// MARK: - PIN Pad (mouse-clickable, keyboard is blocked during lock)

struct PINKey: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(.primary.opacity(0.08), lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(AppStrings.enterDigit(label))
        .focusable()
    }
}

struct PINPadView: View {
    @Binding var entry: String
    let maxLength = 4
    let onComplete: () -> Void
    let onCancel: () -> Void
    var lockedOutMessage: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            if let lockMsg = lockedOutMessage {
                Text(lockMsg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Design.errorRed)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(lockMsg)
            }

            // Dot indicators — hidden from VoiceOver; count spoken via label below
            HStack(spacing: 12) {
                ForEach(0..<maxLength, id: \.self) { i in
                    Circle()
                        .fill(i < entry.count
                              ? AnyShapeStyle(Design.accentGradient)
                              : AnyShapeStyle(Color.primary.opacity(0.18)))
                        .frame(width: 10, height: 10)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: entry.count)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(AppStrings.pinDigitsEntered(entry.count, maxLength))

            VStack(spacing: 5) {
                ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.first) { row in
                    HStack(spacing: 5) {
                        ForEach(row, id: \.self) { n in
                            PINKey(label: "\(n)") { append("\(n)") }
                        }
                    }
                }
                HStack(spacing: 5) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 56, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel PIN entry")
                    .keyboardShortcut(.cancelAction)
                    .focusable()

                    PINKey(label: "0") { append("0") }

                    Button {
                        if !entry.isEmpty { entry.removeLast() }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.secondary)
                            .frame(width: 56, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete last digit")
                    .focusable()
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func append(_ digit: String) {
        guard entry.count < maxLength else { return }
        entry.append(digit)
        if entry.count == maxLength { onComplete() }
    }
}

// MARK: - Unlock Button (shared by LockedView and OverlayView)

struct UnlockButton: View {
    @ObservedObject var cleaningState: CleaningStateManager
    let onFailure: () -> Void

    @State private var showPINPad = false
    @State private var pinEntry = ""
    @State private var pinFailed = false
    @State private var pinLockoutMessage: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            if showPINPad {
                PINPadView(
                    entry: $pinEntry,
                    onComplete: submitPIN,
                    onCancel: {
                        withAnimation(.spring(response: 0.3)) {
                            showPINPad = false
                            pinEntry = ""
                            pinFailed = false
                            pinLockoutMessage = nil
                        }
                    },
                    lockedOutMessage: pinLockoutMessage
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal:   .scale(scale: 0.9).combined(with: .opacity)
                ))
            } else {
                Button {
                    cleaningState.authenticateToUnlock { success in
                        if !success { onFailure() }
                    }
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(stateColor.opacity(0.12))
                                .frame(width: 80, height: 80)
                                .blur(radius: 16)

                            GlassCircle(diameter: 62) {
                                Image(systemName: stateIcon)
                                    .font(.system(size: 26, weight: .light))
                                    .foregroundStyle(stateColor)
                                    .accessibilityHidden(true)
                            }
                            .overlay(
                                Circle()
                                    .stroke(stateColor.opacity(0.45), lineWidth: 1)
                                    .frame(width: 62, height: 62)
                            )
                        }
                        .scaleEffect(cleaningState.authState == .authenticating ? 1.06 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8).repeatWhile(
                                cleaningState.authState == .authenticating, autoreverses: true),
                            value: cleaningState.authState
                        )

                        Text(stateLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(cleaningState.authState == .authenticating || cleaningState.authState == .success)
                .accessibilityLabel(stateLabel)
                .accessibilityHint(stateHint)
                .keyboardShortcut(.defaultAction)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal:   .scale(scale: 0.9).combined(with: .opacity)
                ))

                if cleaningState.pinEnabled && cleaningState.authState != .authenticating {
                    FallbackPill(label: "Use PIN") {
                        withAnimation(.spring(response: 0.3)) {
                            pinEntry = ""
                            pinFailed = false
                            showPINPad = true
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPINPad)
        .onAppear {
            // Macs without Touch ID: if a PIN is set, make the pad the default view
            if !cleaningState.hasTouchID && cleaningState.pinEnabled {
                showPINPad = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func submitPIN() {
        if cleaningState.isPINLockedOut {
            updateLockoutMessage()
            pinEntry = ""
            onFailure()
            return
        }
        if cleaningState.verifyPin(pinEntry) {
            pinLockoutMessage = nil
            withAnimation { showPINPad = false }
            cleaningState.unlockWithVerifiedPIN()
        } else {
            if cleaningState.isPINLockedOut {
                updateLockoutMessage()
            }
            withAnimation(.easeInOut(duration: 0.08).repeatCount(5, autoreverses: true)) {
                pinFailed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pinEntry = ""
                pinFailed = false
            }
            onFailure()
        }
    }

    private func updateLockoutMessage() {
        guard let until = cleaningState.pinLockedUntil else { return }
        let remaining = max(0, Int(until.timeIntervalSinceNow.rounded(.up)))
        pinLockoutMessage = String(format: String(localized: "Too many attempts. Try again in %ds."), remaining)
    }

    private var stateIcon: String {
        switch cleaningState.authState {
        case .idle, .authenticating: return cleaningState.hasTouchID ? "touchid" : "key.fill"
        case .failed:                return "arrow.clockwise"
        case .success:               return "checkmark.circle"
        }
    }

    private var stateLabel: String {
        switch cleaningState.authState {
        case .idle:           return String(localized: "Unlock with Touch ID")
        case .authenticating: return String(localized: "Verifying…")
        case .failed:         return String(localized: "Try Again")
        case .success:        return String(localized: "Unlocked")
        }
    }

    private var stateColor: Color {
        switch cleaningState.authState {
        case .failed:         return Design.errorRed
        case .authenticating: return Design.accentEnd
        case .success:        return Design.accentStart
        default:              return Design.accentEnd
        }
    }

    private var stateHint: String {
        switch cleaningState.authState {
        case .idle:
            if cleaningState.hasTouchID && cleaningState.pinEnabled {
                return String(localized: "Uses Touch ID or PIN to unlock the keyboard")
            } else if cleaningState.hasTouchID {
                return String(localized: "Uses Touch ID to unlock the keyboard")
            } else {
                return String(localized: "Uses PIN to unlock the keyboard")
            }
        case .failed: return String(localized: "Previous attempt failed. Tap to try again.")
        default:      return ""
        }
    }
}

// MARK: - Fallback Pill

struct FallbackPill: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(label))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(GlassCapsuleBackground())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey(label))
        .accessibilityHint("Alternative unlock method")
    }
}

// MARK: - Touch ID Key Note

struct TouchIDKeyNote: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.orange.opacity(0.8))
                .accessibilityHidden(true)
            Text("Physical Touch ID key may trigger macOS lock screen")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            GlassCapsuleBackground()
                .overlay(Capsule().stroke(.orange.opacity(0.2), lineWidth: 0.5))
        )
        .accessibilityLabel("Note: physical Touch ID key may trigger macOS lock screen")
    }
}

// MARK: - Lock Icon (open ↔ closed, animated)

struct LockIconView: View {
    let closed: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Image(systemName: "lock.open.fill")
                .font(.system(size: size, weight: .light))
                .foregroundStyle(.primary)
                .scaleEffect(closed ? 0.5 : 1.0)
                .opacity(closed ? 0 : 1)
                .accessibilityHidden(true)
            Image(systemName: "lock.fill")
                .font(.system(size: size, weight: .light))
                .foregroundStyle(.primary)
                .scaleEffect(closed ? 1.0 : 0.5)
                .opacity(closed ? 1 : 0)
                .accessibilityHidden(true)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: closed)
    }
}

// MARK: - Pulse Rings

struct PulseRings: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animating: Bool
    let count: Int
    let baseSize: CGFloat
    let step: CGFloat
    let maxOpacity: Double

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let ringOpacity = max(0, maxOpacity - Double(i) * 0.02)
                let ringSize = baseSize + CGFloat(i) * step

                Circle()
                    .stroke(.primary.opacity(ringOpacity), lineWidth: 1)
                    .frame(width: ringSize, height: ringSize)
                    .scaleEffect(animating && !reduceMotion ? 1.07 : 1.0)
                    .animation(
                        reduceMotion
                            ? .default
                            : .easeInOut(duration: Timing.pulse)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.32),
                        value: animating
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Countdown Ring View

struct CountdownRingView: View {
    @ObservedObject var cleaningState: CleaningStateManager

    private var progress: Double {
        let total = Double(cleaningState.autoUnlockTimeout.rawValue)
        guard total > 0 else { return 0 }
        return max(0, 1.0 - Double(cleaningState.elapsedSeconds) / total)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                // Ambient glow behind ring (decorative)
                Circle()
                    .fill(RadialGradient(
                        colors: [Design.accentEnd.opacity(0.14), .clear],
                        center: .center, startRadius: 0, endRadius: 90))
                    .frame(width: 180, height: 180)
                    .blur(radius: 22)
                    .accessibilityHidden(true)

                Circle()
                    .stroke(.primary.opacity(0.06), lineWidth: 5)
                    .frame(width: 150, height: 150)
                    .accessibilityHidden(true)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Design.accentGradient,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                    .accessibilityHidden(true)

                VStack(spacing: 3) {
                    Text(cleaningState.remainingTimeString ?? "")
                        .font(.system(size: 46, weight: .thin, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.easeInOut(duration: 0.35), value: cleaningState.elapsedSeconds)
                        .accessibilityLabel(
                            cleaningState.remainingTimeString.map { AppStrings.autoUnlockIn($0) } ?? "")

                    Text("remaining")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: - Overlay Elapsed View (when auto-unlock is off)

struct OverlayElapsedView: View {
    @ObservedObject var cleaningState: CleaningStateManager

    var body: some View {
        VStack(spacing: 8) {
            Text(cleaningState.elapsedTimeString)
                .font(.system(size: 80, weight: .ultraLight, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: cleaningState.elapsedSeconds)
                .accessibilityLabel(AppStrings.lockedFor(cleaningState.elapsedTimeString))

            Text("keyboard locked")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
