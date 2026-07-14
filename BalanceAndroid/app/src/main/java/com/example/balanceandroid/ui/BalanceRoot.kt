package com.example.balanceandroid.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.balanceandroid.FinanceUiState
import com.example.balanceandroid.MainViewModel
import com.example.balanceandroid.data.CategoryDesign
import com.example.balanceandroid.data.FinanceMath
import com.example.balanceandroid.data.TransactionEntity
import com.example.balanceandroid.ui.theme.BalanceGreen
import com.example.balanceandroid.ui.theme.BalanceIndigo
import com.example.balanceandroid.ui.theme.BalancePurple
import com.example.balanceandroid.ui.theme.BalanceRed
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private data class Destination(val route: String, val title: String, val icon: ImageVector)
private val destinations = listOf(
    Destination("overview", "Обзор", Icons.Default.Home),
    Destination("analytics", "Аналитика", Icons.Default.Analytics),
    Destination("transactions", "Операции", Icons.Default.List),
    Destination("budgets", "Бюджеты", Icons.Default.Savings),
    Destination("settings", "Настройки", Icons.Default.Settings),
)

@Composable
fun BalanceRoot(model: MainViewModel, state: FinanceUiState) {
    val nav = rememberNavController()
    val route = nav.currentBackStackEntryAsState().value?.destination?.route ?: "overview"
    Scaffold(
        bottomBar = {
            if (destinations.any { it.route == route }) NavigationBar {
                destinations.forEach { item ->
                    NavigationBarItem(
                        selected = route == item.route,
                        onClick = { nav.navigate(item.route) { popUpTo("overview"); launchSingleTop = true } },
                        icon = { Icon(item.icon, item.title) },
                        label = { Text(item.title) },
                        alwaysShowLabel = false,
                    )
                }
            }
        },
    ) { padding ->
        NavHost(nav, "overview", Modifier.padding(padding)) {
            composable("overview") { OverviewScreen(model, state) }
            composable("analytics") { AnalyticsScreen(state) }
            composable("transactions") { TransactionsScreen(model, state) }
            composable("budgets") { BudgetsScreen(model, state) }
            composable("settings") { SettingsScreen(model, state, nav) }
            composable("categories") { CategoriesScreen(model, state, nav) }
            composable("server") { ServerScreen(model, state, nav) }
        }
    }
}

@Composable
private fun OverviewScreen(model: MainViewModel, state: FinanceUiState) {
    var adjustment by remember { mutableStateOf(false) }
    val (start, end) = periodBounds(1)
    val summary = FinanceMath.summary(state.data.transactions, start, end)
    val spending = FinanceMath.spending(state.data.transactions, start, end)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item { ScreenTitle("Обзор") }
        item {
            Column(
                Modifier.fillMaxWidth().background(
                    Brush.linearGradient(listOf(BalanceIndigo, BalancePurple)), RoundedCornerShape(22.dp),
                ).padding(22.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text("Общий баланс", color = Color.White.copy(alpha = .82f))
                Text(formatMoney(FinanceMath.totalBalance(state.data.transactions), state.currency), color = Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                OutlinedButton(onClick = { adjustment = true }) {
                    Icon(Icons.Default.Tune, null); Spacer(Modifier.size(7.dp)); Text("Скорректировать", color = Color.White)
                }
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricCard("Доходы", formatMoney(summary.income, state.currency), BalanceGreen, Modifier.weight(1f))
                MetricCard("Расходы", formatMoney(summary.expenses, state.currency), BalanceRed, Modifier.weight(1f))
            }
        }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Text("Расходы по категориям", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    SpendingBars(spending, Modifier.fillMaxWidth())
                }
            }
        }
        if (state.data.transactions.isNotEmpty()) {
            item { Text("Последние операции", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) }
            items(state.data.transactions.take(5), key = { it.id }) { TransactionRow(it, state.currency) }
        }
    }
    if (adjustment) BalanceAdjustmentDialog(
        current = FinanceMath.totalBalance(state.data.transactions),
        currency = state.currency,
        onDismiss = { adjustment = false },
        onSave = { target, note -> model.adjustBalance(target, note); adjustment = false },
    )
}

@Composable
private fun AnalyticsScreen(state: FinanceUiState) {
    var months by remember { mutableIntStateOf(1) }
    val bounds = periodBounds(months)
    val summary = FinanceMath.summary(state.data.transactions, bounds.first, bounds.second)
    val spending = FinanceMath.spending(state.data.transactions, bounds.first, bounds.second)
    val savings = if (summary.income > 0) summary.balance / summary.income * 100 else 0.0
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item { ScreenTitle("Аналитика") }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(1 to "Месяц", 3 to "3 месяца", 12 to "12 месяцев").forEach { (value, title) ->
                    FilterChip(selected = months == value, onClick = { months = value }, label = { Text(title) })
                }
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricCard("Доходы", formatMoney(summary.income, state.currency), BalanceGreen, Modifier.weight(1f))
                MetricCard("Расходы", formatMoney(summary.expenses, state.currency), BalanceRed, Modifier.weight(1f))
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricCard("Результат", formatMoney(summary.balance, state.currency), BalanceIndigo, Modifier.weight(1f))
                MetricCard("Сбережения", "%.0f%%".format(savings), BalanceGreen, Modifier.weight(1f))
            }
        }
        item {
            Card { Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("Структура расходов", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                SpendingBars(spending, Modifier.fillMaxWidth())
            } }
        }
    }
}

@Composable
private fun TransactionsScreen(model: MainViewModel, state: FinanceUiState) {
    var search by remember { mutableStateOf("") }
    var kind by remember { mutableStateOf("all") }
    var editing by remember { mutableStateOf<TransactionEntity?>(null) }
    var showingEditor by remember { mutableStateOf(false) }
    val filtered = state.data.transactions.filter {
        (kind == "all" || it.kindRawValue == kind) &&
            (search.isBlank() || it.categoryName.contains(search, true) || it.note.contains(search, true))
    }
    Scaffold(
        floatingActionButton = {
            ExtendedFloatingActionButton(onClick = { editing = null; showingEditor = true }, icon = { Icon(Icons.Default.Add, null) }, text = { Text("Добавить") })
        },
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            item { ScreenTitle("Операции") }
            item { OutlinedTextField(search, { search = it }, Modifier.fillMaxWidth(), label = { Text("Поиск") }, singleLine = true) }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("all" to "Все", "expense" to "Расходы", "income" to "Доходы").forEach { item ->
                        FilterChip(kind == item.first, { kind = item.first }, label = { Text(item.second) })
                    }
                }
            }
            if (filtered.isEmpty()) item { EmptyMessage("Операций пока нет") }
            items(filtered, key = { it.id }) { transaction ->
                Card(Modifier.fillMaxWidth().clickable { editing = transaction; showingEditor = true }) {
                    Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        TransactionRow(transaction, state.currency, Modifier.weight(1f))
                        IconButton({ editing = transaction; showingEditor = true }) { Icon(Icons.Default.Edit, "Изменить") }
                        IconButton({ model.deleteTransaction(transaction) }) { Icon(Icons.Default.Delete, "Удалить", tint = BalanceRed) }
                    }
                }
            }
            item { Spacer(Modifier.height(72.dp)) }
        }
    }
    if (showingEditor) TransactionEditorDialog(model, state, editing, onDismiss = { showingEditor = false })
}

@Composable
private fun BudgetsScreen(model: MainViewModel, state: FinanceUiState) {
    var editing by remember { mutableStateOf(false) }
    val month = MainViewModel.currentMonthStart()
    val budgets = state.data.budgets.filter { it.monthStart == month }
    val bounds = periodBounds(1)
    val spent = FinanceMath.spending(state.data.transactions, bounds.first, bounds.second).associate { it.name to it.amount }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                ScreenTitle("Бюджеты", Modifier.weight(1f))
                Button({ editing = true }) { Icon(Icons.Default.Edit, null); Spacer(Modifier.size(6.dp)); Text("Лимиты") }
            }
        }
        if (budgets.isEmpty()) item { EmptyMessage("Лимиты не заданы") }
        items(budgets, key = { it.id }) { budget ->
            val value = spent[budget.categoryName] ?: 0.0
            val progress = (value / budget.limitAmount.coerceAtLeast(1.0)).toFloat().coerceIn(0f, 1f)
            Card { Column(Modifier.padding(15.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CategoryBadge(CategoryDesign(budget.categoryName, budget.categoryIcon, budget.categoryEmoji, "indigo", "expense"), size = 36)
                    Spacer(Modifier.size(10.dp)); Text(budget.categoryName, Modifier.weight(1f), fontWeight = FontWeight.Bold)
                    Text(formatMoney(value, state.currency))
                }
                LinearProgressIndicator({ progress }, Modifier.fillMaxWidth())
                Text("Лимит: ${formatMoney(budget.limitAmount, state.currency)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            } }
        }
    }
    if (editing) BudgetEditorDialog(model, state, onDismiss = { editing = false })
}

@Composable
private fun SettingsScreen(model: MainViewModel, state: FinanceUiState, nav: NavHostController) {
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { ScreenTitle("Настройки") }
        item { SettingsCard("Отображение") {
            ChoiceRow("Валюта", state.currency, listOf("RUB", "EUR", "USD", "SEK"), model::setCurrency)
            ChoiceRow("Тема", state.theme, listOf("system", "light", "dark"), model::setTheme, label = { when(it) { "light" -> "Светлая"; "dark" -> "Тёмная"; else -> "Системная" } })
        } }
        item { SettingsCard("Данные") {
            SettingsLink("Категории", Icons.Default.Category) { nav.navigate("categories") }
            HorizontalDivider()
            SettingsLink("Сервер и синхронизация", Icons.Default.Sync) { nav.navigate("server") }
            Text("Сохранено операций: ${state.data.transactions.size}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        } }
        item { SettingsCard("Приватность") {
            Text("Данные хранятся локально. Токены сервера шифруются ключом Android Keystore.")
        } }
        item { Text("Версия 1.0.0", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}

@Composable
private fun CategoriesScreen(model: MainViewModel, state: FinanceUiState, nav: NavHostController) {
    var editing by remember { mutableStateOf<com.example.balanceandroid.data.CategoryEntity?>(null) }
    var showEditor by remember { mutableStateOf(false) }
    Scaffold(floatingActionButton = {
        ExtendedFloatingActionButton(
            onClick = { editing = null; showEditor = true },
            icon = { Icon(Icons.Default.Add, null) },
            text = { Text("Категория") }
        )
    }) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            item { BackTitle("Категории") { nav.popBackStack() } }
            if (state.data.categories.isEmpty()) item { EmptyMessage("Своих категорий пока нет") }
            items(state.data.categories, key = { it.id }) { category ->
                Card(Modifier.fillMaxWidth().clickable { editing = category; showEditor = true }) {
                    Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        CategoryBadge(CategoryDesign(category.name, category.icon, category.emoji, category.colorName, category.kindRawValue))
                        Spacer(Modifier.size(12.dp)); Column(Modifier.weight(1f)) { Text(category.name, fontWeight = FontWeight.Bold); Text(if(category.kindRawValue == "income") "Доход" else "Расход", style = MaterialTheme.typography.bodySmall) }
                        IconButton({ editing = category; showEditor = true }) { Icon(Icons.Default.Edit, null) }
                        IconButton({ model.deleteCategory(category) }) { Icon(Icons.Default.Delete, null, tint = BalanceRed) }
                    }
                }
            }
            item { Spacer(Modifier.height(72.dp)) }
        }
    }
    if (showEditor) CategoryEditorDialog(model, state, editing, onDismiss = { showEditor = false })
}

@Composable
private fun ServerScreen(model: MainViewModel, state: FinanceUiState, nav: NavHostController) {
    var server by remember(state.serverUrl) { mutableStateOf(state.serverUrl) }
    var email by remember(state.session?.email, state.serverEmail) { mutableStateOf(state.session?.email ?: state.serverEmail) }
    var password by remember { mutableStateOf("") }
    val savedServerSelected = state.serverUrl.isNotBlank() && server.trim().trimEnd('/') == state.serverUrl
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { BackTitle("Сервер") { nav.popBackStack() } }
        item { SettingsCard("Адрес") {
            OutlinedTextField(server, { server = it }, Modifier.fillMaxWidth(), label = { Text("https://balance.example.com") }, singleLine = true)
            Button({ model.changeServer(server) }, enabled = !state.sync.running) { Text("Сохранить адрес") }
            Text("Для эмулятора локальный сервер доступен как http://10.0.2.2:8080", style = MaterialTheme.typography.bodySmall)
        } }
        item { SettingsCard("Аккаунт") {
            if (state.session == null) {
                OutlinedTextField(email, { email = it }, Modifier.fillMaxWidth(), label = { Text("Email") }, singleLine = true)
                OutlinedTextField(password, { password = it }, Modifier.fillMaxWidth(), label = { Text("Пароль") }, singleLine = true, visualTransformation = PasswordVisualTransformation())
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button({ model.login(email, password) }, enabled = !state.sync.running && savedServerSelected && email.isNotBlank() && password.isNotBlank()) { Text("Войти") }
                    OutlinedButton({ model.register(email, password) }, enabled = !state.sync.running && savedServerSelected && email.isNotBlank() && password.length >= 8) { Text("Регистрация") }
                }
                if (!savedServerSelected) Text("Сначала сохраните адрес сервера", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
            } else {
                Text("Выполнен вход: ${state.session.email}", fontWeight = FontWeight.Bold)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button({ model.sync() }, enabled = !state.sync.running) { Icon(Icons.Default.Sync, null); Spacer(Modifier.size(6.dp)); Text("Синхронизировать") }
                    OutlinedButton({ model.logout() }, enabled = !state.sync.running) { Text("Выйти") }
                }
                OutlinedButton({ model.resetSync() }, enabled = !state.sync.running) { Text("Полная пересинхронизация") }
            }
            if (state.sync.running) LinearProgressIndicator(Modifier.fillMaxWidth())
            state.sync.message?.let { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        } }
    }
}

@Composable private fun ScreenTitle(text: String, modifier: Modifier = Modifier) = Text(text, modifier, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
@Composable private fun BackTitle(text: String, back: () -> Unit) = Row(verticalAlignment = Alignment.CenterVertically) { IconButton(back) { Icon(Icons.Default.ArrowBack, "Назад") }; ScreenTitle(text) }
@Composable private fun EmptyMessage(text: String) = Box(Modifier.fillMaxWidth().padding(30.dp), contentAlignment = Alignment.Center) { Text(text, color = MaterialTheme.colorScheme.onSurfaceVariant) }

@Composable
private fun TransactionRow(value: TransactionEntity, currency: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        CategoryBadge(CategoryDesign(value.categoryName, value.categoryIcon, value.categoryEmoji, value.categoryColorName, value.kindRawValue), size = 38)
        Spacer(Modifier.size(10.dp)); Column(Modifier.weight(1f)) {
            Text(value.categoryName, fontWeight = FontWeight.SemiBold)
            Text(value.note.ifBlank { Instant.ofEpochMilli(value.date).atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ofPattern("d MMM")) }, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
        }
        Text((if(value.kindRawValue == "income") "+" else "−") + formatMoney(value.amount, currency), color = if(value.kindRawValue == "income") BalanceGreen else MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
    }
}

@Composable private fun SettingsCard(title: String, content: @Composable ColumnScope.() -> Unit) = Card(Modifier.fillMaxWidth()) { Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) { Text(title, fontWeight = FontWeight.Bold); content() } }
@Composable private fun SettingsLink(title: String, icon: ImageVector, action: () -> Unit) = Row(Modifier.fillMaxWidth().clickable(onClick = action).padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) { Icon(icon, null); Spacer(Modifier.size(12.dp)); Text(title, Modifier.weight(1f)); Text("›", style = MaterialTheme.typography.titleLarge) }

@Composable
private fun ChoiceRow(title: String, current: String, values: List<String>, onSelect: (String) -> Unit, label: (String) -> String = { it }) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        Row(Modifier.fillMaxWidth().clickable { expanded = true }.padding(vertical = 7.dp)) { Text(title, Modifier.weight(1f)); Text(label(current), color = MaterialTheme.colorScheme.primary) }
        androidx.compose.material3.DropdownMenu(expanded, { expanded = false }) {
            values.forEach { value -> androidx.compose.material3.DropdownMenuItem({ Text(label(value)) }, { onSelect(value); expanded = false }) }
        }
    }
}
