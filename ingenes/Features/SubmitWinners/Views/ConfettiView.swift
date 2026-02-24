// ConfettiView.swift
// Ingenes
//
// Celebration confetti animation using CAEmitterLayer

import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    var duration: TimeInterval = 3.0

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // Create emitter layer
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -50)
        emitterLayer.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitterLayer.emitterShape = .line

        // Create confetti cells with different colors
        let colors: [UIColor] = [
            UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1.0), // Green
            UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),   // Gold
            UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),   // Blue
            UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),  // Red
            UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0), // Purple
            UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),   // Orange
        ]

        let shapes = ["circle.fill", "star.fill", "square.fill", "triangle.fill"]

        emitterLayer.emitterCells = colors.enumerated().map { index, color in
            let cell = CAEmitterCell()
            cell.birthRate = 10
            cell.lifetime = 8.0
            cell.lifetimeRange = 2.0
            cell.velocity = 250
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 5
            cell.spinRange = 10
            cell.scale = 0.15
            cell.scaleRange = 0.1
            cell.scaleSpeed = -0.02
            cell.color = color.cgColor
            cell.alphaSpeed = -0.3

            // Create different shapes
            let shapeIndex = index % shapes.count
            if let image = UIImage(systemName: shapes[shapeIndex])?.withTintColor(color, renderingMode: .alwaysOriginal) {
                cell.contents = image.cgImage
            } else {
                // Fallback to circle
                cell.contents = createConfettiImage(color: color).cgImage
            }

            return cell
        }

        view.layer.addSublayer(emitterLayer)

        // Stop emitting after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 1.0) {
            emitterLayer.birthRate = 0
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    // Create a simple confetti rectangle image
    private func createConfettiImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 12, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - SwiftUI Confetti Alternative

struct SwiftUIConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    let colors: [Color] = [
        AppTheme.primaryGreen,
        .yellow,
        .blue,
        .red,
        .purple,
        .orange
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    private func generateConfetti(in size: CGSize) {
        for _ in 0..<100 {
            let piece = ConfettiPiece(
                color: colors.randomElement()!,
                x: CGFloat.random(in: 0...size.width),
                delay: Double.random(in: 0...0.5)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let delay: Double
    let rotation = Double.random(in: 0...360)
    let scale = CGFloat.random(in: 0.5...1.0)
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    @State private var offsetY: CGFloat = -50
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8 * piece.scale, height: 12 * piece.scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: piece.x - UIScreen.main.bounds.width / 2, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: 3.0)
                    .delay(piece.delay)
                ) {
                    offsetY = UIScreen.main.bounds.height + 100
                    rotation = piece.rotation + 720
                }
                withAnimation(
                    .easeIn(duration: 1.0)
                    .delay(piece.delay + 2.0)
                ) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ConfettiView()
            .ignoresSafeArea()
    }
}
