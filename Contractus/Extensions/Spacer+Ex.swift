//
//  Spacer+Ex.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 11.10.2023.
//

import SwiftUI

extension Spacer {
    public func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.001).onTapGesture(count: count, perform: action)
            self
        }
    }
}
