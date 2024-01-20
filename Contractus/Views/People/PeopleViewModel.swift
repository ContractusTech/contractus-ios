//
//  PeopleViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.01.2024.
//

import Foundation

final class PeopleViewModel: ViewModel {
        
    enum Input {
        case load
    }
    
    struct State {
    }
    
    @Published private(set) var state: State

    init() {
        self.state = .init()
    }
    
    func trigger(_ input: Input, after: AfterTrigger?) {
        switch input {
        case .load:
            return
        }
    }
}
