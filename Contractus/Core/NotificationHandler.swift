import Foundation

enum NotificationHandler {

    struct OpenDealParams {
        let recipients: [String]
        let dealId: String
    }

    static func handler(notification: [AnyHashable : Any]) {
        if let dealId = notification["deal_id"] as? String,
           let recipients = notification["recipients"] as? String
        {
            NotificationCenter.default.post(
                name: NSNotification.openDeal,
                object: OpenDealParams(recipients: recipients.split(separator: ",").map { String($0) }, dealId: dealId),
                userInfo: nil
            )
        }
    }
}
