//
//  Buttons.swift
//  Contractus
//
//  Created by Simon Hudishkin on 15.11.2022.
//

import SwiftUI

struct CButton: View {

    enum Style {
        case primary, secondary, warn, cancel
        var background: Color {
            switch self {
            case .secondary:
                return R.color.buttonBackgroundSecondary.color
            case .primary:
                return R.color.buttonBackgroundPrimary.color
            case .warn:
                return R.color.yellow.color
            case .cancel:
                return R.color.buttonBackgroundCancel.color
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
                return R.color.buttonTextCancel.color
            }
        }
    }

    enum Size {
        case `default`, large

        var edge: EdgeInsets {
            switch self {
            case .large:
                return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            case .default:
                return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
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

    @State private var rotateDegree : CGFloat = 0

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else {
                return
            }
            action()
        } label: {

            switch size {
            case .`default`:
                ZStack(alignment: .leading) {
                    if isLoading {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                R.color.secondaryBackground.color,
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
                                .foregroundColor(style.textColor)
                                .padding(.top, (title.isEmpty) ? 3 : 0)
                                .padding(.bottom, (title.isEmpty) ? 3 : 0)
                        }
                        if !title.isEmpty {
                            Text(title)
                                .foregroundColor(style.textColor)
                                .font(.body.weight(.medium))
                                .padding(.leading, (isLoading && !title.isEmpty) ? 20 : 0)
                        }
                    }

                }
                .padding(size.edge)
                .background(style.background)
                .cornerRadius(roundedCorner ? 24 : 12)
                .opacity(isLoading || isDisabled ? 0.6 : 1.0)
            case .large:
                HStack(spacing: 6) {
                    Spacer()
                    if isLoading {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                R.color.secondaryBackground.color,
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
                                .foregroundColor(style.textColor)
                                //.padding(.top, (title.isEmpty) ? 4 : 0)
                                //.padding(.bottom, (title.isEmpty) ? 4 : 0)
                        }
                        if !title.isEmpty {
                            Text(title)
                                .foregroundColor(style.textColor)
                                .font(.body.weight(.semibold))
                        }

                    }

                    Spacer()
                }
                .padding(size.edge)
                .background(style.background)
                .cornerRadius(roundedCorner ? 30 : 16)
                .opacity(isLoading || isDisabled ? 0.6 : 1.0)
            }
        }
        .disabled(isLoading || isDisabled)
    }
}


struct CButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                Group {
                    CButton(title: "Text", style: .primary, size: .default, isLoading: false) { }

                    CButton(title: "Text", style: .secondary, size: .default, isLoading: false) { }

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

    }
}
