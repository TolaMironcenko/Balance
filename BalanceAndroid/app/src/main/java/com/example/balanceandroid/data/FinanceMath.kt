package com.example.balanceandroid.data

data class FinanceSummary(val income: Double, val expenses: Double) {
    val balance: Double get() = income - expenses
}

data class CategoryTotal(
    val name: String,
    val icon: String,
    val emoji: String,
    val colorName: String,
    val amount: Double,
)

object FinanceMath {
    fun totalBalance(items: List<TransactionEntity>): Double = items.sumOf {
        if (it.kindRawValue == "income") it.amount else -it.amount
    }

    fun summary(items: List<TransactionEntity>, start: Long, endExclusive: Long): FinanceSummary {
        val filtered = items.filter { !it.isBalanceAdjustment && it.date >= start && it.date < endExclusive }
        return FinanceSummary(
            income = filtered.filter { it.kindRawValue == "income" }.sumOf { it.amount },
            expenses = filtered.filter { it.kindRawValue == "expense" }.sumOf { it.amount },
        )
    }

    fun spending(items: List<TransactionEntity>, start: Long, endExclusive: Long): List<CategoryTotal> =
        items.asSequence()
            .filter { it.kindRawValue == "expense" && !it.isBalanceAdjustment && it.date >= start && it.date < endExclusive }
            .groupBy { it.categoryName }
            .map { (name, values) ->
                val first = values.first()
                CategoryTotal(name, first.categoryIcon, first.categoryEmoji, first.categoryColorName, values.sumOf { it.amount })
            }
            .sortedByDescending { it.amount }
}
