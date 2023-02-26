//
//  TextEditor+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 03.12.2022.
//

import SwiftUI

extension View {

    @ViewBuilder
    public func setBackground(color: Color) -> some View {
        if #available(iOS 16.0, *) {
            self
                .scrollContentBackground(.hidden)
                .background(color)
        } else {
            self
                .textEditorBackground {
                    R.color.textFieldBackground.color
                }
        }
    }

    private func textEditorBackground<V>(@ViewBuilder _ content: () -> V) -> some View where V : View {
        self
            .onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
            .background(content())
    }

}
