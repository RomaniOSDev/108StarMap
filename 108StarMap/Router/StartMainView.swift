//
//  SMInitialLoadingView.swift
//  108StarMap
//

import SwiftUI

@inline(__always)
private func _dp(_ v: [UInt8], _ s: UInt8) -> String {
    String(bytes: v.map { $0 ^ s }, encoding: .utf8) ?? ""
}

private struct SMAnimationConfig {
    let duration: TimeInterval
    let damping: CGFloat
    let velocity: CGFloat

    static let standard = SMAnimationConfig(duration: 1.0, damping: 0.8, velocity: 0.5)
    static let quick = SMAnimationConfig(duration: 0.4, damping: 1.0, velocity: 0.0)

    var isInteractive: Bool { damping < 1.0 }
}

private enum SMLoadPhase {
    case pending, active, done
    var label: String {
        switch self {
        case .pending: return "waiting"
        case .active: return "processing"
        case .done: return "finished"
        }
    }
    var isComplete: Bool { self == .done }
}

struct SMDualArcSpinner: View {
    var completionRatio: Double
    @State private var arcAngle: Double = 0.0
    var width: CGFloat = 72
    var height: CGFloat = 72

    private let arcSpan: Double = 0.35

    var body: some View {
        let lineW = width / 15
        let tailGradient = AngularGradient(
            colors: [.clear, .white.opacity(0.4), .white],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(arcSpan * 360)
        )

        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: lineW)
                .frame(width: width, height: height)
                .offset(y: 3)
                .blur(radius: 2)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.gray.opacity(0.4),
                            Color.gray.opacity(0.25),
                            Color.white.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: lineW
                )
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            _arcSegment(gradient: tailGradient, lineW: lineW, angle: arcAngle)
            _arcSegment(gradient: tailGradient, lineW: lineW, angle: arcAngle + 180)

            if completionRatio > 0.5 {
                SMCompletionBadge()
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                arcAngle = 360
            }
        }
        .onChange(of: completionRatio) { newProgress in
            if newProgress >= 100 {
                arcAngle = 0
            }
        }
    }

    private func _arcSegment(gradient: AngularGradient, lineW: CGFloat, angle: Double) -> some View {
        Circle()
            .trim(from: 0.0, to: arcSpan)
            .stroke(
                gradient,
                style: StrokeStyle(lineWidth: lineW, lineCap: .round)
            )
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            .shadow(color: .white.opacity(0.6), radius: 1)
    }
}

struct SMCompletionBadge: View {
    private let indicatorTint = Color.green

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(indicatorTint)
                .frame(width: 72, height: 72)
                .opacity(0.3)
                .shadow(color: indicatorTint.opacity(0.4), radius: 8)
            Circle()
                .foregroundStyle(indicatorTint)
                .frame(width: 60, height: 60)
                .opacity(0.6)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            Circle()
                .foregroundStyle(indicatorTint)
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                .shadow(color: indicatorTint.opacity(0.5), radius: 4)
            Image(systemName: _dp([0xC4, 0xCF, 0xC2, 0xC4, 0xCC, 0xCA, 0xC6, 0xD5, 0xCC], 0xA7))
                .resizable()
                .frame(width: 18, height: 13)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
        }
    }
}

struct SMInitialLoadingView: View {
    @State private var _phase: SMLoadPhase = .pending

    var body: some View {
        ZStack {
            Image(.ladoi)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                SMDualArcSpinner(completionRatio: 0)

                Text(_dp([0xEB, 0xC8, 0xC6, 0xC3, 0xCE, 0xC9, 0xC0, 0x89, 0x89, 0x89], 0xA7))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

#Preview {
    SMInitialLoadingView()
}
