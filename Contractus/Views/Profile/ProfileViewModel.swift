//
//  ProfileViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 18.01.2024.
//

import Foundation

final class ProfileViewModel: ViewModel {
    
    enum ProfileMode {
        case `public`, `private`
    }
    
    enum Input {
        case load
    }
    
    struct State {
        var mode: ProfileMode
    }
    
    @Published private(set) var state: State

    init(mode: ProfileMode) {
        self.state = .init(mode: mode)
    }
    
    func trigger(_ input: Input, after: AfterTrigger?) {
        switch input {
        case .load:
            return
        }
    }
}
