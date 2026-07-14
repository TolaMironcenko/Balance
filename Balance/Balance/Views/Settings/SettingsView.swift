import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    private var exportDocument: CSVDocument {
        CSVDocument(transactions: transactions)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Отображение") {
                    Picker("Валюта", selection: $currencyCode) {
                        ForEach(SupportedCurrency.allCases) { currency in
                            Text(currency.rawValue).tag(currency.rawValue)
                        }
                    }

                    Picker("Тема", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme.rawValue)
                        }
                    }
                }

                Section("Категории") {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Управление категориями", systemImage: "square.grid.2x2")
                    }
                }

                Section("Данные") {
                    NavigationLink {
                        ServerAccountView()
                    } label: {
                        Label("Сервер и синхронизация", systemImage: "server.rack")
                    }

                    ShareLink(
                        item: exportDocument,
                        preview: SharePreview(
                            "Операции",
                            image: Image(systemName: "tablecells")
                        )
                    ) {
                        Label("Экспортировать CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(transactions.isEmpty)

                    LabeledContent("Операций сохранено", value: transactions.count.formatted())
                }

                Section("Приватность") {
                    Label {
                        Text(syncDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    LabeledContent("Версия", value: "3.1.1")
                } footer: {
                    Text("Баланс помогает видеть картину расходов, но не является финансовой консультацией.")
                }
            }
            .navigationTitle("Настройки")
        }
    }

    private var syncDescription: String {
        if BalanceModelContainer.isCloudSyncEnabled {
            return "Данные синхронизируются через приватную базу CloudKit вашего Apple ID."
        }
        return "Без входа данные остаются на устройстве. Собственный сервер можно подключить выше без iCloud и платной Apple Developer Team."
    }
}
