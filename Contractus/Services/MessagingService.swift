//
//  MessagingService.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 25.09.2023.
//

import FirebaseMessaging

final class MessagingService {

    // MARK: - Shared
    static let shared = MessagingService()
    
    func subscribe(to topic: String) {
#if DEBUG
        debugPrint("MessagingService: subscribe to \(topic)")
#endif
        Messaging.messaging().subscribe(toTopic: topic)
    }

    func unsubscribe(from topic: String) {
#if DEBUG
        debugPrint("MessagingService: unsubscribe from \(topic)")
#endif
        Messaging.messaging().unsubscribe(fromTopic: topic)
    }
}
