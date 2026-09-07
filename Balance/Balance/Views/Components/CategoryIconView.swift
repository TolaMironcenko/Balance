import SwiftUI

struct CategoryIconView: View {
    let systemName: String
    let emoji: String
    let tint: Color
    var size: CGFloat = 18
    var containerSize: CGFloat?

    var body: some View {
        Group {
            if let containerSize {
                glyph
                    .frame(width: containerSize, height: containerSize)
                    .background(tint.opacity(0.12), in: Circle())
            } else {
                glyph
                    .frame(width: size + 12, height: size + 12)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyph: some View {
        if emoji.isEmpty {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(tint)
        } else {
            Text(emoji)
                .font(.system(size: size))
        }
    }
}

#Preview("Иконки") {
    HStack(spacing: 16) {
        CategoryIconView(systemName: "cart.fill", emoji: "", tint: .orange, containerSize: 40)
        CategoryIconView(systemName: "car.fill", emoji: "", tint: .blue)
        CategoryIconView(systemName: "banknote.fill", emoji: "", tint: .green, size: 24, containerSize: 52)
    }
    .padding()
}

#Preview("Эмодзи") {
    HStack(spacing: 16) {
        CategoryIconView(systemName: "star.fill", emoji: "☕️", tint: .brown, size: 21, containerSize: 40)
        CategoryIconView(systemName: "star.fill", emoji: "🐶", tint: .purple, size: 21, containerSize: 40)
    }
    .padding()
}
