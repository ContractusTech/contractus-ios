//
//  CopyContent.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.09.2022.
//

import Foundation
import SwiftUI

fileprivate enum Constants {
    static let successCopyImage = Image(systemName: "checkmark")
    static let copyImage = Image(systemName: "square.on.square")
}

struct CopyContentView: View {

    enum ContentType: Int {
        case privateKey = 4, publicKey = 5, common = 0
    }
    
    let content: String
    let contentType: ContentType

    var action: (String) -> Void

    @State var copiedNotification: Bool = false

    var body: some View {
        HStack {
            Text(ContentMask.mask(from: content, visibleCount: contentType.rawValue))
                .font(.title3)
                .foregroundColor(R.color.secondaryText.color)
            Spacer()
            Button {
                copiedNotification = true
                ImpactGenerator.light()
                UIPasteboard.general.string = content
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                    copiedNotification = false
                })
                action(content)
            } label: {
                HStack {
                    if copiedNotification {
                        Constants.successCopyImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(R.color.baseGreen.color)
                    } else {
                        Constants.copyImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(R.color.textBase.color)
                    }
                }
                .frame(width: 24, height: 24)
                .animation(.easeInOut(duration: 0.2), value: copiedNotification)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .background(R.color.textFieldBackground.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
        )
    }
}


struct CopyContentView_Previews: PreviewProvider {
    static var previews: some View {
        CopyContentView(content: "text123123123", contentType: .common) { _ in

        }
    }
}

