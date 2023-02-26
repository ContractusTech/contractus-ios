//
//  Buttons.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import SwiftUI

fileprivate let DISABLE_OPACITY = 0.4

struct PrimaryLargeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Btn(configuration: configuration)
    }

    struct Btn: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.body.weight(.bold))
                .padding()
                .background(isEnabled ? R.color.buttonBackgroundPrimary.color : R.color.buttonBackgroundPrimary.color.opacity(DISABLE_OPACITY))
                .foregroundColor(isEnabled ? R.color.buttonTextPrimary.color : R.color.buttonTextPrimary.color.opacity(DISABLE_OPACITY))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.03))
               //  .opacity(isEnabled ? 1.0 : DISABLE_OPACITY)
        }
    }
}

struct SecondaryLargeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Btn(configuration: configuration)
    }

    struct Btn: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.body.weight(.bold))
                .padding()
                .background(isEnabled ? R.color.buttonBackgroundSecondary.color : R.color.buttonBackgroundSecondary.color.opacity(DISABLE_OPACITY))
                .foregroundColor(isEnabled ? R.color.buttonTextSecondary.color : R.color.buttonTextSecondary.color.opacity(DISABLE_OPACITY))
//                .overlay(RoundedRectangle(cornerRadius: 24)
//                    .stroke(R.color.buttonBackgroundPrimary.color, lineWidth: 1.2))
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.03))
                .cornerRadius(24)
                // .opacity(isEnabled ? 1 : DISABLE_OPACITY)
        }
    }
}

struct SecondaryMediumButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Btn(configuration: configuration)
    }

    struct Btn: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                //.background(isEnabled ? R.color.buttonBackgroundSecondary.color : R.color.buttonBackgroundSecondary.color.opacity(DISABLE_OPACITY))
                .foregroundColor(isEnabled ? R.color.buttonTextSecondary.color : R.color.buttonTextSecondary.color.opacity(DISABLE_OPACITY))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(R.color.buttonBackgroundPrimary.color, lineWidth: 1.2))
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.03))
                // .opacity(isEnabled ? 1 : DISABLE_OPACITY)
        }
    }
}

struct RoundedSecondaryMediumButton: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        Btn(configuration: configuration)
    }

    struct Btn: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.body)
                .padding(12)
                .foregroundColor(isEnabled ? R.color.buttonTextSecondary.color : R.color.buttonTextSecondary.color.opacity(DISABLE_OPACITY))
                .clipShape(RoundedRectangle(cornerRadius: 50))

                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(R.color.buttonBackgroundPrimary.color, lineWidth: 1.4))
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.03))
                // .opacity(isEnabled ? 1 : DISABLE_OPACITY)
        }
    }
}

struct PrimaryMediumButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Btn(configuration: configuration)
    }

    struct Btn: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(isEnabled ? R.color.buttonBackgroundPrimary.color : R.color.buttonBackgroundPrimary.color.opacity(DISABLE_OPACITY))
                .foregroundColor(isEnabled ? R.color.buttonTextPrimary.color : R.color.buttonTextPrimary.color.opacity(DISABLE_OPACITY))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.03))
                // .opacity(isEnabled ? 1 : DISABLE_OPACITY)
        }
    }
}

