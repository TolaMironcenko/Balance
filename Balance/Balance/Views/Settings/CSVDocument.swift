import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct CSVDocument: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            document.data
        }
        .suggestedFileName("balance-transactions.csv")
    }

    init(transactions: [FinanceTransaction]) {
        var rows = ["Дата,Тип,Категория,Сумма,Заметка"]
        let formatter = ISO8601DateFormatter()

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let values = [
                formatter.string(from: transaction.date),
                transaction.isBalanceAdjustment ? "Корректировка" : transaction.kind.title,
                transaction.categoryName,
                String(transaction.amount),
                transaction.note
            ]
            rows.append(values.map(Self.escape).joined(separator: ","))
        }

        data = rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    private static func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
