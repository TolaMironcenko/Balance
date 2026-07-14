package com.example.balanceandroid.sync

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.balanceandroid.BalanceApplication

class SyncWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val app = applicationContext as BalanceApplication
        if (app.sessions.load() == null || app.preferences.serverUrl.isBlank()) return Result.success()
        return if (app.syncRepository.sync()) Result.success() else Result.retry()
    }
}
