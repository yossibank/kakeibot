package com.yossibank.kakeibot.featuremodels.screens.settings.wallets

import com.yossibank.kakeibot.core.concepts.wallet.Wallet

val Wallet.Kind.title: String
    get() = when (this) {
        Wallet.Kind.cash -> "現金"
        Wallet.Kind.bank -> "銀行"
        Wallet.Kind.card -> "カード"
        Wallet.Kind.emoney -> "電子マネー"
        Wallet.Kind.point -> "ポイント"
        Wallet.Kind.other -> "その他"
        Wallet.Kind.investment -> "投資"
        Wallet.Kind.loan -> "借入"
    }
