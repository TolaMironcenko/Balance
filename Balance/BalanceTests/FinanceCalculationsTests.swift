import Foundation
import XCTest
@testable import Balance

final class FinanceCalculationsTests: XCTestCase {
    func testSummarySeparatesIncomeAndExpenses() {
        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1_000)
        )
        let transactions = [
            FinanceTransaction(
                amount: 100_000,
                date: Date(timeIntervalSince1970: 100),
                categoryName: "Зарплата",
                categoryIcon: "banknote.fill",
                kind: .income
            ),
            FinanceTransaction(
                amount: 25_000,
                date: Date(timeIntervalSince1970: 200),
                categoryName: "Продукты",
                categoryIcon: "cart.fill",
                kind: .expense
            )
        ]

        let summary = FinanceCalculations.summary(
            transactions: transactions,
            in: interval
        )

        XCTAssertEqual(summary.income, 100_000)
        XCTAssertEqual(summary.expenses, 25_000)
        XCTAssertEqual(summary.balance, 75_000)
    }

    func testSummaryIgnoresTransactionsOutsidePeriod() {
        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1_000)
        )
        let transaction = FinanceTransaction(
            amount: 5_000,
            date: Date(timeIntervalSince1970: 2_000),
            categoryName: "Покупки",
            categoryIcon: "bag.fill",
            kind: .expense
        )

        let summary = FinanceCalculations.summary(
            transactions: [transaction],
            in: interval
        )

        XCTAssertEqual(summary.income, 0)
        XCTAssertEqual(summary.expenses, 0)
    }

    func testSpendingGroupsCustomCategoryAndKeepsColor() {
        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1_000)
        )
        let transactions = [100.0, 250.0].map { amount in
            FinanceTransaction(
                amount: amount,
                date: Date(timeIntervalSince1970: 100),
                categoryName: "Питомец",
                categoryIcon: "pawprint.fill",
                categoryEmoji: "🐾",
                categoryColorName: "teal",
                kind: .expense
            )
        }

        let spending = FinanceCalculations.spendingByCategory(
            transactions: transactions,
            in: interval
        )

        XCTAssertEqual(spending.count, 1)
        XCTAssertEqual(spending.first?.name, "Питомец")
        XCTAssertEqual(spending.first?.amount, 350)
        XCTAssertEqual(spending.first?.emoji, "🐾")
        XCTAssertEqual(spending.first?.colorName, "teal")
    }

    func testTotalBalanceUsesAllIncomeAndExpenses() {
        let transactions = [
            FinanceTransaction(
                amount: 80_000,
                categoryName: "Зарплата",
                categoryIcon: "banknote.fill",
                kind: .income
            ),
            FinanceTransaction(
                amount: 30_000,
                categoryName: "Дом",
                categoryIcon: "house.fill",
                kind: .expense
            ),
            FinanceTransaction(
                amount: 2_500,
                categoryName: "Корректировка",
                categoryIcon: "slider.horizontal.3",
                isBalanceAdjustment: true,
                kind: .income
            )
        ]

        XCTAssertEqual(
            FinanceCalculations.totalBalance(transactions: transactions),
            52_500
        )
    }

    func testPeriodSummaryIgnoresBalanceAdjustment() {
        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1_000)
        )
        let adjustment = FinanceTransaction(
            amount: 12_000,
            date: Date(timeIntervalSince1970: 100),
            categoryName: "Корректировка",
            categoryIcon: "slider.horizontal.3",
            isBalanceAdjustment: true,
            kind: .income
        )

        let summary = FinanceCalculations.summary(
            transactions: [adjustment],
            in: interval
        )

        XCTAssertEqual(summary.income, 0)
        XCTAssertEqual(summary.expenses, 0)
        XCTAssertEqual(
            FinanceCalculations.totalBalance(transactions: [adjustment]),
            12_000
        )
    }

    func testDeletionJournalDeduplicatesAndRemovesRecords() {
        let recordID = UUID().uuidString
        let firstDate = Date.now.addingTimeInterval(-2)
        let secondDate = Date.now.addingTimeInterval(-1)

        SyncDeletionStore.add(entity:"transaction", recordID:recordID, updatedAt:firstDate)
        SyncDeletionStore.add(entity:"transaction", recordID:recordID, updatedAt:secondDate)

        let records = SyncDeletionStore.page(
            through:.now,
            offset:0,
            limit:10_000
        ).filter { $0.recordID == recordID }
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.updatedAt, secondDate)

        SyncDeletionStore.remove(entity:"transaction", recordID:recordID, through:.now)
        XCTAssertFalse(SyncDeletionStore.page(through:.now, offset:0, limit:10_000).contains {
            $0.recordID == recordID
        })
    }
}
