import SwiftUI

struct TransactionRow: View {
    let transaction: FinanceTransaction
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(
                systemName: transaction.categoryIcon,
                emoji: transaction.categoryEmoji,
                tint: categoryTint,
                size: transaction.categoryEmoji.isEmpty ? 15 : 21,
                containerSize: 40
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.categoryName)
                    .font(.body.weight(.medium))
                Text(transaction.note.isEmpty ? transaction.date.formatted(date: .abbreviated, time: .omitted) : transaction.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(signedAmount)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.kind == .income ? .green : .primary)
        }
        .padding(.vertical, 10)
    }

    private var categoryTint: Color {
        if transaction.categoryColorName == "auto" {
            return FinanceCategory.find(named: transaction.categoryName)?.tint ?? .indigo
        }
        return FinanceCategory.color(named: transaction.categoryColorName)
    }

    private var signedAmount: String {
        let prefix = transaction.kind == .income ? "+" : "−"
        return prefix + transaction.amount.formattedCurrency(code: currencyCode)
    }
}
