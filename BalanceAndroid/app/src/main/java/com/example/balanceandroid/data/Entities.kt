package com.example.balanceandroid.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "transactions", indices = [Index(value = ["updatedAt"]), Index(value = ["date"])])
data class TransactionEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val amount: Double,
    val date: Long = System.currentTimeMillis(),
    val note: String = "",
    val categoryName: String,
    val categoryIcon: String = "circle",
    val categoryEmoji: String = "",
    val categoryColorName: String = "indigo",
    val isBalanceAdjustment: Boolean = false,
    val kindRawValue: String = "expense",
    val updatedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "categories", indices = [Index(value = ["updatedAt"]), Index(value = ["name", "kindRawValue"])])
data class CategoryEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val icon: String = "star",
    val emoji: String = "",
    val colorName: String = "indigo",
    val kindRawValue: String = "expense",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "budgets", indices = [Index(value = ["updatedAt"]), Index(value = ["monthStart"])])
data class BudgetEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val categoryName: String,
    val categoryIcon: String = "circle",
    val categoryEmoji: String = "",
    val limitAmount: Double,
    val monthStart: Long,
    val updatedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "deletion_journal", indices = [Index(value = ["updatedAt"])])
data class DeletionEntity(
    @PrimaryKey val id: String,
    val entity: String,
    val recordId: String,
    val updatedAt: Long = System.currentTimeMillis(),
) {
    companion object {
        fun create(entity: String, recordId: String, updatedAt: Long = System.currentTimeMillis()) =
            DeletionEntity("$entity:$recordId", entity, recordId, updatedAt)
    }
}

data class CategoryDesign(
    val name: String,
    val icon: String,
    val emoji: String = "",
    val colorName: String,
    val kind: String,
)

object BuiltInCategories {
    val expenses = listOf(
        CategoryDesign("Продукты", "cart.fill", "", "orange", "expense"),
        CategoryDesign("Транспорт", "car.fill", "", "blue", "expense"),
        CategoryDesign("Дом", "house.fill", "", "indigo", "expense"),
        CategoryDesign("Развлечения", "gamecontroller.fill", "", "pink", "expense"),
        CategoryDesign("Здоровье", "cross.case.fill", "", "red", "expense"),
        CategoryDesign("Покупки", "bag.fill", "", "purple", "expense"),
        CategoryDesign("Подписки", "repeat", "", "cyan", "expense"),
        CategoryDesign("Образование", "book.fill", "", "mint", "expense"),
        CategoryDesign("Другое", "ellipsis.circle.fill", "", "gray", "expense"),
    )
    val incomes = listOf(
        CategoryDesign("Зарплата", "banknote.fill", "", "green", "income"),
        CategoryDesign("Подработка", "laptopcomputer", "", "teal", "income"),
        CategoryDesign("Инвестиции", "chart.line.uptrend.xyaxis", "", "blue", "income"),
        CategoryDesign("Подарок", "gift.fill", "", "pink", "income"),
        CategoryDesign("Другое", "plus.circle.fill", "", "gray", "income"),
    )
}
