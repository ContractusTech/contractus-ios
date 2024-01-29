import Foundation

enum NotificationHandler {

    enum NotificationType: Equatable {
        case open(OpenDealParams)
    }

    struct OpenDealParams: Equatable {
        let recipients: [String]
        let dealId: String
    }

    static var notification: NotificationType? = nil

    static func handler(notification: [AnyHashable : Any]) {
        if let dealId = notification["deal_id"] as? String,
           let recipients = notification["recipients"] as? String
        {
            let params = OpenDealParams(
                recipients: recipients.split(separator: ",").map { String($0) },
                dealId: dealId)

            Self.notification = NotificationType.open(params)

            NotificationCenter.default.post(
                name: NSNotification.openDeal,
                object: params,
                userInfo: nil
            )
        }
    }
}
