//
//  BaseViewModifier.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.08.2022.
//

import SwiftUI

struct BaseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(R.color.mainBackground.color)
    }
}


struct FullSizeModifier: ViewModifier{

    func body(content: Content) -> some View {
        content
            .frame(
                  minWidth: 0,
                  maxWidth: .infinity,
                  minHeight: 0,
                  maxHeight: .infinity,
                  alignment: .topLeading
                )
            .padding()
    }

}

struct NavigationBarModifier: ViewModifier {

    var backgroundColor: UIColor?
    var titleColor: UIColor?

    init(backgroundColor: UIColor?, titleColor: UIColor?) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear

        // TODO: - Need Fix. After changing the mode the navigation bar is not updated
        appearance.backgroundEffect = UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
        appearance.titleTextAttributes = [.foregroundColor: titleColor ?? .white]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]

        let scrollingAppearance = UINavigationBarAppearance()
        scrollingAppearance.configureWithTransparentBackground()
        scrollingAppearance.backgroundColor = backgroundColor

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollingAppearance
        UINavigationBar.appearance().compactAppearance = scrollingAppearance
    }

    func body(content: Content) -> some View {
        ZStack{
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor ?? .clear)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

