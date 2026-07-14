package com.example.balanceandroid

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.balanceandroid.data.BudgetEntity
import com.example.balanceandroid.data.BuiltInCategories
import com.example.balanceandroid.data.CategoryDesign
import com.example.balanceandroid.data.CategoryEntity
import com.example.balanceandroid.data.FinanceDao
import com.example.balanceandroid.data.TransactionEntity
import com.example.balanceandroid.sync.ServerPreferences
import com.example.balanceandroid.sync.ServerSession
import com.example.balanceandroid.sync.SyncRepository
import com.example.balanceandroid.sync.SyncStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId

data class FinanceData(
    val transactions: List<TransactionEntity> = emptyList(),
    val categories: List<CategoryEntity> = emptyList(),
    val budgets: List<BudgetEntity> = emptyList(),
)

data class FinanceUiState(
    val data: FinanceData = FinanceData(),
    val sync: SyncStatus = SyncStatus(),
    val session: ServerSession? = null,
    val currency: String = "RUB",
    val theme: String = "system",
    val serverUrl: String = "",
    val serverEmail: String = "",
)

class MainViewModel(
    private val dao: FinanceDao,
    private val preferences: ServerPreferences,
    private val syncRepository: SyncRepository,
) : ViewModel() {
    private val settingsRevision = MutableStateFlow(0)
    private val financeData = combine(
        dao.observeTransactions(),
        dao.observeCategories(),
        dao.observeBudgets(),
    ) { transactions, categories, budgets -> FinanceData(transactions, categories, budgets) }

    val state: StateFlow<FinanceUiState> = combine(
        financeData,
        syncRepository.status,
        syncRepository.session,
        settingsRevision,
    ) { data, sync, session, _ ->
        FinanceUiState(
            data = data,
            sync = sync,
            session = session,
            currency = preferences.currency,
            theme = preferences.theme,
            serverUrl = preferences.serverUrl,
            serverEmail = preferences.email,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), FinanceUiState())

    init { viewModelScope.launch { syncRepository.sync() } }

    fun categories(kind: String, data: FinanceData = state.value.data): List<CategoryDesign> {
        val builtIn = if (kind == "income") BuiltInCategories.incomes else BuiltInCategories.expenses
        return builtIn + data.categories.filter { it.kindRawValue == kind }.map {
            CategoryDesign(it.name, it.icon, it.emoji, it.colorName, it.kindRawValue)
        }
    }

    fun saveTransaction(
        existing: TransactionEntity?, amount: Double, kind: String, category: CategoryDesign,
        note: String, date: Long,
    ) = viewModelScope.launch {
        val now = System.currentTimeMillis()
        dao.upsertTransaction((existing ?: TransactionEntity(amount = amount, categoryName = category.name)).copy(
            amount = amount,
            date = date,
            note = note.trim(),
            categoryName = category.name,
            categoryIcon = category.icon,
            categoryEmoji = category.emoji,
            categoryColorName = category.colorName,
            kindRawValue = kind,
            updatedAt = now,
        ))
    }

    fun deleteTransaction(value: TransactionEntity) = viewModelScope.launch { dao.deleteTransaction(value) }

    fun adjustBalance(target: Double, note: String) = viewModelScope.launch {
        val current = com.example.balanceandroid.data.FinanceMath.totalBalance(state.value.data.transactions)
        val difference = target - current
        if (kotlin.math.abs(difference) < 0.005) return@launch
        dao.upsertTransaction(TransactionEntity(
            amount = kotlin.math.abs(difference),
            note = note.ifBlank { "Ручная корректировка баланса" },
            categoryName = "Корректировка",
            categoryIcon = "tune",
            categoryColorName = "indigo",
            isBalanceAdjustment = true,
            kindRawValue = if (difference > 0) "income" else "expense",
        ))
    }

    fun saveCategory(existing: CategoryEntity?, name: String, kind: String, icon: String, emoji: String, color: String) = viewModelScope.launch {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return@launch
        val now = System.currentTimeMillis()
        if (existing != null) {
            val oldName = existing.name
            val updated = existing.copy(name = trimmed, icon = icon, emoji = emoji, colorName = color, updatedAt = now)
            dao.upsertCategory(updated)
            dao.upsertTransactions(dao.transactionsForCategory(oldName).map {
                it.copy(categoryName = trimmed, categoryIcon = icon, categoryEmoji = emoji, categoryColorName = color, updatedAt = now)
            })
            dao.upsertBudgets(dao.budgetsForCategory(oldName).map {
                it.copy(categoryName = trimmed, categoryIcon = icon, categoryEmoji = emoji, updatedAt = now)
            })
        } else {
            dao.upsertCategory(CategoryEntity(name = trimmed, icon = icon, emoji = emoji, colorName = color, kindRawValue = kind))
        }
    }

    fun deleteCategory(value: CategoryEntity) = viewModelScope.launch { dao.deleteCategory(value) }

    fun saveBudget(category: CategoryDesign, amount: Double, monthStart: Long = currentMonthStart()) = viewModelScope.launch {
        val existing = state.value.data.budgets.firstOrNull { it.categoryName == category.name && it.monthStart == monthStart }
        if (amount <= 0 && existing != null) dao.deleteBudget(existing)
        else if (amount > 0) dao.upsertBudget((existing ?: BudgetEntity(
            categoryName = category.name,
            categoryIcon = category.icon,
            categoryEmoji = category.emoji,
            limitAmount = amount,
            monthStart = monthStart,
        )).copy(limitAmount = amount, categoryIcon = category.icon, categoryEmoji = category.emoji, updatedAt = System.currentTimeMillis()))
    }

    fun setCurrency(value: String) { preferences.currency = value; settingsRevision.value++ }
    fun setTheme(value: String) { preferences.theme = value; settingsRevision.value++ }

    fun changeServer(value: String) = viewModelScope.launch {
        runCatching { syncRepository.changeServer(value) }
            .onSuccess { settingsRevision.value++ }
    }
    fun login(email: String, password: String) = viewModelScope.launch { syncRepository.login(email, password) }
    fun register(email: String, password: String) = viewModelScope.launch { syncRepository.register(email, password) }
    fun logout() = viewModelScope.launch { syncRepository.logout() }
    fun sync() = viewModelScope.launch { syncRepository.sync() }
    fun resetSync() = viewModelScope.launch { syncRepository.resetAndSync() }

    companion object {
        fun currentMonthStart(now: Long = System.currentTimeMillis()): Long = Instant.ofEpochMilli(now)
            .atZone(ZoneId.systemDefault()).withDayOfMonth(1).toLocalDate().atStartOfDay(ZoneId.systemDefault())
            .toInstant().toEpochMilli()
    }

    class Factory(private val application: BalanceApplication) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = MainViewModel(
            application.database.financeDao(), application.preferences, application.syncRepository,
        ) as T
    }
}
