//
//  TextField.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.09.2022.
//

import SwiftUI

struct LargeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(16)
                .background(R.color.thirdBackground.color)
                .cornerRadius(12)
        }
    
}


