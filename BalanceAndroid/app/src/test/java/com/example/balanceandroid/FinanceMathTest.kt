package com.example.balanceandroid

import com.example.balanceandroid.data.FinanceMath
import com.example.balanceandroid.data.TransactionEntity
import org.junit.Assert.assertEquals
import org.junit.Test

class FinanceMathTest {
    @Test
    fun summarySeparatesIncomeExpensesAndAdjustments() {
        val items = listOf(
            TransactionEntity(amount = 1000.0, date = 100, categoryName = "Зарплата", kindRawValue = "income"),
            TransactionEntity(amount = 250.0, date = 200, categoryName = "Продукты", kindRawValue = "expense"),
            TransactionEntity(amount = 50.0, date = 300, categoryName = "Корректировка", kindRawValue = "income", isBalanceAdjustment = true),
        )
        val summary = FinanceMath.summary(items, 0, 1000)
        assertEquals(1000.0, summary.income, 0.001)
        assertEquals(250.0, summary.expenses, 0.001)
        assertEquals(750.0, summary.balance, 0.001)
        assertEquals(800.0, FinanceMath.totalBalance(items), 0.001)
    }

    @Test
    fun spendingGroupsCategories() {
        val items = listOf(
            TransactionEntity(amount = 100.0, date = 100, categoryName = "Дом", categoryColorName = "indigo"),
            TransactionEntity(amount = 200.0, date = 200, categoryName = "Дом", categoryColorName = "indigo"),
        )
        val spending = FinanceMath.spending(items, 0, 1000)
        assertEquals(1, spending.size)
        assertEquals(300.0, spending.first().amount, 0.001)
    }
}
