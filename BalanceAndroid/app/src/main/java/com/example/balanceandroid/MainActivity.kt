package com.example.balanceandroid

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.balanceandroid.ui.BalanceRoot
import com.example.balanceandroid.ui.theme.BalanceTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val model: MainViewModel = viewModel(factory = MainViewModel.Factory(application as BalanceApplication))
            val state by model.state.collectAsStateWithLifecycle()
            BalanceTheme(theme = state.theme) {
                BalanceRoot(model, state)
            }
        }
    }
}
