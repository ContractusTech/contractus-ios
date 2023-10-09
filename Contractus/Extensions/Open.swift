import SwiftUI

func openEmailSupport() {
    let appURL = URL(string: "mailto:\(AppConfig.supportEmail)")!
    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
}

func openTelegramSupport() {
    let appURL = URL(string: AppConfig.supportTelegram)!
    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
}

func openCoinstore() {
    UIApplication.shared.open(AppConfig.coinstoreUrl, options: [:], completionHandler: nil)
}

func openRaydium() {
    UIApplication.shared.open(AppConfig.radiumUrl, options: [:], completionHandler: nil)
}

func openPancake() {
    UIApplication.shared.open(AppConfig.pancakeUrl, options: [:], completionHandler: nil)
}
