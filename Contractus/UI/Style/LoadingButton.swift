//
//  LoadingButton.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.09.2022.
//

import SwiftUI

// MARK: - LargePrimaryLoadingButton

public struct LargePrimaryLoadingButton<Content: View>: View {

    var isLoading: Bool
    let content: Content
    var action: () -> () = {}

    public init(
        action: @escaping () -> Void,
        isLoading: Bool,
        @ViewBuilder label: () -> Content)
    {
        self.isLoading = isLoading
        content = label()
        self.action = action
    }

    public var body: some View {
        BaseLoadingButton(
            action: {
                action()
            },
            isLoading: isLoading,
            label: {
                content
            },
            loaderColor: R.color.baseSeparator.color,
            style: PrimaryLargeButton())
    }
}

// MARK: - LargeSecondaryLoadingButton

public struct LargeSecondaryLoadingButton<Content: View>: View {

    var isLoading: Bool
    let content: Content
    var action: () -> () = {}

    public init(
        action: @escaping () -> Void,
        isLoading: Bool,
        @ViewBuilder label: () -> Content)
    {
        self.isLoading = isLoading
        content = label()
        self.action = action
    }

    public var body: some View {
        BaseLoadingButton(
            action: {
                action()
            },
            isLoading: isLoading,
            label: {
                content
            },
            loaderColor: R.color.textBase.color,
            style: SecondaryLargeButton())
    }
}

// MARK: - MediumPrimaryLoadingButton

public struct MediumPrimaryLoadingButton<Content: View>: View {

    @Binding var isLoading: Bool
    let content: Content
    var action: () -> () = {}

    public init(
        action: @escaping () -> Void,
        isLoading: Binding<Bool>,
        @ViewBuilder label: () -> Content)
    {
        self._isLoading = isLoading
        content = label()
        self.action = action
    }

    public var body: some View {
        BaseLoadingButton(
            action: {
                action()
            },
            isLoading: isLoading,
            label: {
                content
            },
            loaderColor: R.color.baseSeparator.color,
            style: PrimaryMediumButton())
    }
}

// MARK: - MediumSecondaryLoadingButton

public struct MediumSecondaryLoadingButton<Content: View>: View {

    var isLoading: Bool
    let content: Content
    var action: () -> () = {}

    public init(
        action: @escaping () -> Void,
        isLoading: Bool,
        @ViewBuilder label: () -> Content)
    {
        self.isLoading = isLoading
        content = label()
        self.action = action
    }

    public var body: some View {
        BaseLoadingButton(
            action: {
                action()
            },
            isLoading: isLoading,
            label: {
                content
            },
            loaderColor: R.color.baseSeparator.color,
            style: SecondaryMediumButton())
    }
}

// MARK: - BaseLoadingButton

public struct BaseLoadingButton<Content: View, Style: ButtonStyle>: View {

    var isLoading: Bool
    let style: Style
    let content: Content
    let loaderColor: Color
    var action: () -> () = {}

    @State private var rotateDegree : CGFloat = 0

    public init(
        action: @escaping () -> Void,
        isLoading: Bool,
        @ViewBuilder label: () -> Content,
        loaderColor: Color,
        style: Style)
    {
        self.isLoading = isLoading
        content = label()
        self.action = action
        self.style = style
        self.loaderColor = loaderColor
    }

    public var body: some View {
        Button(action: {
            action()
        }, label: {
            ZStack {
                content.opacity(isLoading ? 0.2 : 1)
                if isLoading {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            loaderColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                        .rotationEffect(Angle(degrees: rotateDegree))
                        .onAppear {
                            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                                self.rotateDegree = 360
                            }
                        }
                        .frame(width: 20, height: 20)
                }
            }
        })
        .buttonStyle(style)
        .disabled(isLoading)
    }

}
