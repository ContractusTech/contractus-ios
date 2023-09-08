import SwiftUI

func openEmailSupport() {
    let appURL = URL(string: "mailto:\(AppConfig.supportEmail)")!
    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
}
