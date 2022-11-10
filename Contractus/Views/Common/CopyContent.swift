//
//  CopyContent.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.09.2022.
//

import Foundation
import SwiftUI

fileprivate enum Constants {
    static let copyImage = Image(systemName: "doc.on.doc")
}

struct CopyContentView: View {

    enum ContentType: Int {
        case privateKey = 4, common = 10
    }

    let content: String
    let contentType: ContentType
    var action: (String) -> Void

    var body: some View {
        HStack {
            Text(KeyFormatter.format(from: content, visibleCount: contentType.rawValue))
                .font(.title3)
            Spacer()
            Button {
                action(content)
            } label: {
                Constants.copyImage
                    .foregroundColor(R.color.textBase.color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
            .fill(R.color.thirdBackground.color)
            .background(RoundedRectangle(cornerRadius: 10).stroke(R.color.baseSeparator.color, lineWidth: 1)))
    }
}


struct CopyContent_Previews: PreviewProvider {
    static var previews: some View {
        CopyContentView(content: "text", contentType: .common) { _ in

        }
    }
}

