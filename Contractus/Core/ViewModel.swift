//
//  ViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import Combine

typealias AfterTrigger = () -> Void

protocol ViewModel: ObservableObject where ObjectWillChangePublisher.Output == Void {
    associatedtype State
    associatedtype Input

    var state: State { get }
    func trigger(_ input: Input, after: AfterTrigger?)
}

extension AnyViewModel: Identifiable where State: Identifiable {
    var id: State.ID {
        state.id
    }
}

@dynamicMemberLookup
final class AnyViewModel<State, Input>: ViewModel {

    // MARK: Stored properties
    private let wrappedObjectWillChange: () -> AnyPublisher<Void, Never>
    private let wrappedState: () -> State
    private let wrappedTrigger: (Input, AfterTrigger?) -> Void

    // MARK: Computed properties
    var objectWillChange: AnyPublisher<Void, Never> {
        wrappedObjectWillChange()
    }

    var state: State {
        wrappedState()
    }

    // MARK: Methods
    func trigger(_ input: Input, after: AfterTrigger? = nil) {
        wrappedTrigger(input, after)
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }

    // MARK: Initialization
    init<V: ViewModel>(_ viewModel: V) where V.State == State, V.Input == Input {
        self.wrappedObjectWillChange = { viewModel.objectWillChange.eraseToAnyPublisher() }
        self.wrappedState = { viewModel.state }
        self.wrappedTrigger = viewModel.trigger
    }

}
