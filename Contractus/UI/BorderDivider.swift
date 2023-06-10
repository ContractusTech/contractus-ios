//
//  BorderDivider.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 08.06.2023.
//

import SwiftUI

struct BorderDivider: View {
    var color: Color = .gray
    var width: CGFloat = 1
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: width)
            .edgesIgnoringSafeArea(.horizontal)
    }
}
struct BorderDivider_Previews: PreviewProvider {
    static var previews: some View {
        BorderDivider()
    }
}
