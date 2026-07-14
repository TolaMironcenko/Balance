import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: Double
    let currencyCode: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(amount.formattedCurrency(code: currencyCode))
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}
