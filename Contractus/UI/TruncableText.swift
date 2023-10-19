//
//  TruncableText.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 18.10.2023.
//

import SwiftUI

struct TruncableText: View {
  let text: Text
  let lineLimit: Int?
  @State private var intrinsicSize: CGSize = .zero
  @State private var truncatedSize: CGSize = .zero
  let isTruncatedUpdate: (_ isTruncated: Bool) -> Void

  var body: some View {
      text
          .lineLimit(lineLimit)
          .readSize { size in
              truncatedSize = size
              isTruncatedUpdate(truncatedSize != intrinsicSize)
          }
          .background(
            text
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .readSize { size in
                    intrinsicSize = size
                    isTruncatedUpdate(truncatedSize != intrinsicSize)
                }
          )
  }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}
