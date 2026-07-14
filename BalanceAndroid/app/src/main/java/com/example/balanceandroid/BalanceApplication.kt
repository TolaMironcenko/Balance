package com.example.balanceandroid

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.balanceandroid.data.AppDatabase
import com.example.balanceandroid.sync.SecureSessionStore
import com.example.balanceandroid.sync.ServerPreferences
import com.example.balanceandroid.sync.SyncRepository
import com.example.balanceandroid.sync.SyncWorker
import java.util.concurrent.TimeUnit

class BalanceApplication : Application() {
    val database by lazy { AppDatabase.get(this) }
    val preferences by lazy { ServerPreferences(this) }
    val sessions by lazy { SecureSessionStore(this) }
    val syncRepository by lazy { SyncRepository(database, preferences, sessions) }

    override fun onCreate() {
        super.onCreate()
        val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "balance-periodic-sync",
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }
}
