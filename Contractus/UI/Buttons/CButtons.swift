//
//  Buttons.swift
//  Contractus
//
//  Created by Simon Hudishkin on 15.11.2022.
//

import SwiftUI

struct CButton: View {

    enum Style {
        case primary, secondary, warn, cancel, success
        var background: Color {
            switch self {
            case .secondary:
                return R.color.buttonBackgroundSecondary.color
            case .primary:
                return R.color.buttonBackgroundPrimary.color
            case .warn:
                return R.color.buttonBackgroundWarn.color
            case .cancel:
                return R.color.buttonBackgroundCancel.color
            case .success:
                return R.color.baseGreen.color
            }
        }

        var borderColor: Color {
            switch self {
            case .secondary:
                return R.color.buttonBorderSecondary.color
            case .primary:
                return .clear //R.color.buttonBorderSecondary.color
            case .warn:
                return R.color.buttonBorderWarn.color
            case .cancel:
                return R.color.buttonBorderCancel.color
            case .success:
                return R.color.baseGreen.color
            }
        }

        var textColor: Color {
            switch self {
            case .secondary:
                return R.color.buttonTextSecondary.color
            case .primary:
                return R.color.buttonTextPrimary.color
            case .warn:
                return R.color.buttonTextSecondary.color
            case .cancel:
                return R.color.buttonTextSecondary.color
            case .success:
                return R.color.white.color
            }
        }
    }

    enum Size {
        case `default`, large, small

        var edge: EdgeInsets {
            switch self {
            case .large:
                return EdgeInsets(top: 18, leading: 26, bottom: 18, trailing: 26)
            case .small:
                return EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
            case .default:
                return EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            }
        }

        var font: Font {
            switch self {
            case .large:
                return .headline //Font.title3.weight(.regular)
            case .small:
                return .footnote
            case .default:
                return .callout.weight(.medium) //Font.headline
            }

        }
    }

    let title: String
    var icon: Image? = nil
    let style: Self.Style
    let size: Self.Size
    let isLoading: Bool

    var roundedCorner: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    private var cornerRadius: CGFloat {
        switch size {
        case .default:
            return roundedCorner ? 24 : 13
        case .small:
            return roundedCorner ? 12 : 7
        case .large:
            return roundedCorner ? 34 : 16
        }
    }

    @State private var rotateDegree : CGFloat = 0

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else {
                return
            }
            action()
        } label: {
            switch size {
            case .`default`, .small:
                ZStack(alignment: .leading) {
                    if isLoading {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                style.textColor.opacity(isLoading || isDisabled ? 0.4 : 1.0),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                            .rotationEffect(Angle(degrees: rotateDegree))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    self.rotateDegree = 360
                                }
                            }
                            .frame(width: 12, height: 12)
                            .padding(.top, title.isEmpty ? 4.7 : 0)
                            .padding(.bottom, title.isEmpty ? 4.7 : 0)
                    }
                    HStack {
                        if !isLoading, let icon = icon {
                            icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundColor(style.textColor.opacity(isLoading || isDisabled ? 0.4 : 1.0))
                                .padding(.top, (title.isEmpty) ? 3 : 0)
                                .padding(.bottom, (title.isEmpty) ? 3 : 0)
                        }
                        if !title.isEmpty {
                            Text(title)
                                .foregroundColor(style.textColor.opacity(isLoading || isDisabled ? 0.6 : 1.0))
                                .font(size.font)
                                .padding(.leading, (isLoading && !title.isEmpty) ? 20 : 0)
                        }
                    }

                }
                .padding(size.edge)
                .background(style.background.opacity(isLoading || isDisabled ? 0.4 : 1.0))
                .cornerRadius(cornerRadius)
                // .opacity(isLoading || isDisabled ? 0.6 : 1.0)
                .overlay {
                    RoundedRectangle(cornerRadius: roundedCorner ? 23 : 12)
                        .stroke(style.borderColor.opacity(isLoading || isDisabled ? 0.3 : 1.0), lineWidth: 1)
                        .padding(0.4)
                }
            case .large:
                HStack(spacing: 6) {
                    Spacer()
                    if isLoading {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                style.textColor.opacity(isLoading || isDisabled ? 0.3 : 1.0),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .rotationEffect(Angle(degrees: rotateDegree))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    self.rotateDegree = 360
                                }
                            }
                            .frame(width: 18, height: 18)
                    }
                    HStack {
                        if !isLoading, let icon = icon {
                            icon
                                .resizable()
                                .frame(width: 19, height: 19)
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(style.textColor.opacity(isLoading || isDisabled ? 0.4 : 1.0))
                        }
                        if !title.isEmpty {
                            Text(title)
                                .foregroundColor(style.textColor.opacity(isLoading || isDisabled ? 0.6 : 1.0))
                                .font(size.font)
                        }

                    }

                    Spacer()
                }

                .padding(size.edge)
                .background(style.background.opacity(isLoading || isDisabled ? 0.4 : 1.0))
                .cornerRadius(roundedCorner ? 34 : 16)
//                .opacity(isLoading || isDisabled ? 0.6 : 1.0)
                .overlay {
                    RoundedRectangle(cornerRadius: roundedCorner ? 34 : 16)
                        .stroke(style.borderColor.opacity(isLoading || isDisabled ? 0.3 : 1.0), lineWidth: 1)
                        .padding(0.3)
                }
            }
        }

        .disabled(isLoading || isDisabled)
//        .shadow(color: style == .primary ? .black.opacity(0.1) : .clear, radius: style == .primary ? 7 : 0, y: 2)

    }
}


struct CButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                Group {
                    CButton(title: "Text", style: .secondary, size: .small, isLoading: false, roundedCorner: true) { }

                    CButton(title: "Text", style: .primary, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .cancel, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .success, size: .large, isLoading: false, isDisabled: true) {}

                    CButton(title: "Text", icon: Image(systemName: "key.viewfinder"), style: .success, size: .large, isLoading: false, isDisabled: false) {}

                    CButton(title: "Text", style: .primary, size: .large, isLoading: false) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: false) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: false) { }
                }
                Group {

                    HStack {
                        CButton(title: "", style: .primary, size: .default, isLoading: true) { }
                        CButton(title: "Text", style: .primary, size: .default, isLoading: true) { }
                    }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: true) { }

                    CButton(title: "Text", style: .primary, size: .large, isLoading: true) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: true) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: true) { }

                    CButton(title: "Text", style: .cancel, size: .large, isLoading: true) { }
                }
                Group {

                    HStack {
                        CButton(title: "", style: .primary, size: .default, isLoading: true, roundedCorner: true) { }
                        CButton(title: "Text", style: .primary, size: .default, isLoading: true, roundedCorner: true) { }
                    }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: true, roundedCorner: true) { }

                    CButton(title: "Text", style: .primary, size: .large, isLoading: true, roundedCorner: true) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: true, roundedCorner: true) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: true, roundedCorner: true) { }
                }

                Group {
                    CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .warn, size: .large, isLoading: false, roundedCorner: false) { }

                    CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .default, isLoading: false) { }

                    HStack {
                        CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .default, isLoading: false) { }
                        
                        CButton(title: "", icon: Image(systemName: "arrow.down.to.line.compact"), style: .secondary, size: .default, isLoading: false) { }
                        CButton(title: "Change", style: .secondary, size: .default, isLoading: false) { }
                    }

                    CButton(title: "", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .large, isLoading: false) { }
                }


            }
        }
        .previewDisplayName("Light theme")
        .preferredColorScheme(.light)

        ScrollView {
            VStack {
                Group {
                    CButton(title: "Text", style: .primary, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .success, size: .large, isLoading: false, isDisabled: true) {}

                    CButton(title: "Text", icon: Image(systemName: "key.viewfinder"), style: .success, size: .large, isLoading: false, isDisabled: false) {}


                    CButton(title: "Text", style: .primary, size: .large, isLoading: false) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: false) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: false) { }

                    CButton(title: "Text", style: .cancel, size: .large, isLoading: false) { }
                }
                Group {

                    HStack {
                        CButton(title: "", style: .primary, size: .default, isLoading: true) { }
                        CButton(title: "Text", style: .primary, size: .default, isLoading: true) { }
                    }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: true) { }

                    CButton(title: "Text", style: .primary, size: .large, isLoading: true) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: true) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: true) { }

                    CButton(title: "Text", style: .cancel, size: .large, isLoading: true) { }
                }
                Group {

                    HStack {
                        CButton(title: "", style: .primary, size: .default, isLoading: true, roundedCorner: true) { }
                        CButton(title: "Text", style: .primary, size: .default, isLoading: true, roundedCorner: true) { }
                    }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: true, roundedCorner: true) { }

                    CButton(title: "Text", style: .primary, size: .large, isLoading: true, roundedCorner: true) {}

                    CButton(title: "Text", style: .secondary, size: .large, isLoading: true, roundedCorner: true) { }

                    CButton(title: "Text", style: .warn, size: .large, isLoading: true, roundedCorner: true) { }
                }

                Group {
                    CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .warn, size: .large, isLoading: false, roundedCorner: false) { }

                    CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .default, isLoading: false) { }

                    HStack {
                        CButton(title: "Text", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .default, isLoading: false) { }

                        CButton(title: "", icon: Image(systemName: "arrow.down.to.line.compact"), style: .secondary, size: .default, isLoading: false) { }
                        CButton(title: "Change", style: .secondary, size: .default, isLoading: false) { }
                    }

                    CButton(title: "", icon: Image(systemName: "slider.vertical.3"), style: .secondary, size: .large, isLoading: false) { }
                }


            }
        }
        .previewDisplayName("Dark theme")
        .preferredColorScheme(.dark)

    }
}
