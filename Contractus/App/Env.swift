import Foundation

struct Env {
    static var APPLE_APP_ID: String {
        Bundle.main.infoDictionary?["APPLE_APP_ID"] as? String ?? ""
    }

    static var APPSFLYER_DEV_KEY: String {
        Bundle.main.infoDictionary?["APPSFLYER_DEV_KEY"] as? String ?? ""
    }
}
