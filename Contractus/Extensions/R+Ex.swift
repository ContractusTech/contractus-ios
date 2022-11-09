//
//  R+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import SwiftUI
import Rswift

// MARK: - ImageResource
extension ImageResource {
    var image: Image {
        Image(name)
    }
}

// MARK: - ColorResource
extension ColorResource {
    var color: Color {
        Color(name)
    }
}

// MARK: - FontResource
extension FontResource {
    func font(size: CGFloat) -> Font {
        Font.custom(fontName, size: size)
    }
}
