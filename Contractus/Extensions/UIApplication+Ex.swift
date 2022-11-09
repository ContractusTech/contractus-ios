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
}

