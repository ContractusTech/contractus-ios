//
//  View+DebugPrint.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import SwiftUI

extension View {
    func DebugPrint(_ print: Any?) -> some View {
        debugPrint(print)
        return EmptyView()
    }
}


