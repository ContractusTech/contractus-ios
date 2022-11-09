//
//  LazyView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.10.2022.
//

import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
