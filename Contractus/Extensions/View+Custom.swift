//
//  View+Custom.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.08.2022.
//

import SwiftUI
import SolanaSwift

extension View {
    func fullSize() -> some View {
        self.modifier(FullSizeModifier())
    }

    func baseBackground() -> some View {
        self.modifier(BaseModifier())
    }

    func navigationBarColor(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }

    func navigationBarColor() -> some View {
        self.navigationBarColor(backgroundColor: R.color.mainBackground(), titleColor: R.color.textBase())
    }

    func endEditing() {
        UIApplication.shared.endEditing()
    }

    func tintIfCan(_ color: Color) -> some View {
        if #available(iOS 16.0, *) {
            return self.tint(color)
        } else {
            return self
        }
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
