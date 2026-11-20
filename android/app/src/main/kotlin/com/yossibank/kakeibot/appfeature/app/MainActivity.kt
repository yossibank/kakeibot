package com.yossibank.kakeibot.appfeature.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class MainActivity : ComponentActivity() {
    private var link: String? by mutableStateOf(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        enableEdgeToEdge()

        if (savedInstanceState == null) {
            link = intent.getStringExtra(EXTRA_LINK)
        }

        setContent {
            RootView(
                link = link,
                onOpenLink = { link = null },
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        link = intent.getStringExtra(EXTRA_LINK)
    }

    companion object {
        const val EXTRA_LINK = "link"
    }
}
