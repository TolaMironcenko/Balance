package com.example.balanceandroid.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

val BalanceIndigo = Color(0xFF5B5BD6)
val BalancePurple = Color(0xFF8B5CF6)
val BalanceGreen = Color(0xFF16A36A)
val BalanceRed = Color(0xFFE05252)

private val LightColors = lightColorScheme(
    primary = BalanceIndigo,
    secondary = BalancePurple,
    tertiary = BalanceGreen,
    background = Color(0xFFF7F7FB),
    surface = Color.White,
    surfaceVariant = Color(0xFFECECF5),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFB8B5FF),
    secondary = Color(0xFFD0BCFF),
    tertiary = Color(0xFF6DD7A8),
    background = Color(0xFF111116),
    surface = Color(0xFF1A1A22),
    surfaceVariant = Color(0xFF292936),
)

@Composable
fun BalanceTheme(theme: String, content: @Composable () -> Unit) {
    val dark = when (theme) {
        "dark" -> true
        "light" -> false
        else -> isSystemInDarkTheme()
    }
    val view = LocalView.current
    val activity = view.context as? Activity
    if (!view.isInEditMode && activity != null) {
        SideEffect {
            val controller = WindowCompat.getInsetsController(activity.window, view)
            controller.isAppearanceLightStatusBars = !dark
        }
    }
    MaterialTheme(colorScheme = if (dark) DarkColors else LightColors, content = content)
}
