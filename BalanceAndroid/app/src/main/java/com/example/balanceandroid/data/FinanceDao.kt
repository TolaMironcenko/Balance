package com.example.balanceandroid.data

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow

@Dao
interface FinanceDao {
    @Query("SELECT * FROM transactions ORDER BY date DESC")
    fun observeTransactions(): Flow<List<TransactionEntity>>

    @Query("SELECT * FROM categories ORDER BY createdAt")
    fun observeCategories(): Flow<List<CategoryEntity>>

    @Query("SELECT * FROM budgets ORDER BY monthStart DESC, categoryName")
    fun observeBudgets(): Flow<List<BudgetEntity>>

    @Upsert suspend fun upsertTransaction(value: TransactionEntity)
    @Upsert suspend fun upsertTransactions(values: List<TransactionEntity>)
    @Upsert suspend fun upsertCategory(value: CategoryEntity)
    @Upsert suspend fun upsertCategories(values: List<CategoryEntity>)
    @Upsert suspend fun upsertBudget(value: BudgetEntity)
    @Upsert suspend fun upsertBudgets(values: List<BudgetEntity>)
    @Upsert suspend fun upsertDeletion(value: DeletionEntity)

    @Query("SELECT * FROM transactions WHERE id = :id LIMIT 1")
    suspend fun transaction(id: String): TransactionEntity?
    @Query("SELECT * FROM categories WHERE id = :id LIMIT 1")
    suspend fun category(id: String): CategoryEntity?
    @Query("SELECT * FROM budgets WHERE id = :id LIMIT 1")
    suspend fun budget(id: String): BudgetEntity?

    @Query("SELECT * FROM transactions WHERE categoryName = :name")
    suspend fun transactionsForCategory(name: String): List<TransactionEntity>
    @Query("SELECT * FROM budgets WHERE categoryName = :name")
    suspend fun budgetsForCategory(name: String): List<BudgetEntity>

    @Query("DELETE FROM transactions WHERE id = :id") suspend fun deleteTransactionDirect(id: String)
    @Query("DELETE FROM categories WHERE id = :id") suspend fun deleteCategoryDirect(id: String)
    @Query("DELETE FROM budgets WHERE id = :id") suspend fun deleteBudgetDirect(id: String)
    @Query("DELETE FROM deletion_journal WHERE entity = :entity AND recordId = :recordId AND updatedAt <= :through")
    suspend fun clearDeletion(entity: String, recordId: String, through: Long)

    @Query("SELECT * FROM transactions WHERE updatedAt >= :after AND updatedAt <= :through ORDER BY updatedAt LIMIT :limit OFFSET :offset")
    suspend fun transactionChanges(after: Long, through: Long, limit: Int, offset: Int): List<TransactionEntity>
    @Query("SELECT * FROM categories WHERE updatedAt >= :after AND updatedAt <= :through ORDER BY updatedAt LIMIT :limit OFFSET :offset")
    suspend fun categoryChanges(after: Long, through: Long, limit: Int, offset: Int): List<CategoryEntity>
    @Query("SELECT * FROM budgets WHERE updatedAt >= :after AND updatedAt <= :through ORDER BY updatedAt LIMIT :limit OFFSET :offset")
    suspend fun budgetChanges(after: Long, through: Long, limit: Int, offset: Int): List<BudgetEntity>
    @Query("SELECT * FROM deletion_journal WHERE updatedAt <= :through ORDER BY updatedAt LIMIT :limit OFFSET :offset")
    suspend fun deletionChanges(through: Long, limit: Int, offset: Int): List<DeletionEntity>

    @Transaction
    suspend fun deleteTransaction(value: TransactionEntity) {
        upsertDeletion(DeletionEntity.create("transaction", value.id))
        deleteTransactionDirect(value.id)
    }

    @Transaction
    suspend fun deleteBudget(value: BudgetEntity) {
        upsertDeletion(DeletionEntity.create("budget", value.id))
        deleteBudgetDirect(value.id)
    }

    @Transaction
    suspend fun deleteCategory(value: CategoryEntity) {
        budgetsForCategory(value.name).forEach { deleteBudget(it) }
        upsertDeletion(DeletionEntity.create("category", value.id))
        deleteCategoryDirect(value.id)
    }
}
