//
//  UIApplication+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.09.2022.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var currentKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
    }

    var rootViewController: UIViewController? {
        currentKeyWindow?.rootViewController
    }

    static func closeAllModal(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            var controllers: [UIViewController] = []
            var nestedController: UIViewController? = UIApplication.shared.rootViewController?.presentedViewController
            while(nestedController != nil) {
                controllers.append(nestedController!)
                nestedController = nestedController?.presentedViewController
            }

            let group = DispatchGroup()
            for vc in controllers.reversed() {
                group.enter()
                vc.dismiss(animated: true) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion()
            }
        }
    }

}

