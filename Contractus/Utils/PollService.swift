//
//  PollingService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 18.04.2023.
//

import Foundation

final class PollService<T: Decodable> {
    enum HandlerResult {
        case success
        case error(Error? = nil)
        case wait
    }

    typealias PollServiceRequest = (_ callback: @escaping (Result<T, Error>) -> Void) -> Void
    let requestId = UUID()
    private let request: PollServiceRequest
    private let operation = OperationQueue()
    private var timer: DispatchSourceTimer?
    private let interval: Int

    private(set) var isPolling: Bool = false

    var handler: ((T?) -> HandlerResult)?
    fileprivate var notify: ((_ requestId: UUID, _ result: HandlerResult) -> Void)?

    // MARK: - Initialization

    init(request: @escaping PollServiceRequest, interval: Int = 5) {
        self.interval = interval
        self.request = request
    }

    func startPoll() {
        timer = createTimer()
        timer?.resume()
        isPolling = true
    }

    func endPoll() {
        timer?.cancel()
        timer = nil
        isPolling = false
    }

    deinit {
        endPoll()
    }

    // MARK: - Private Methods

    private func createTimer() -> DispatchSourceTimer {
        let queue = DispatchQueue.global(qos: .background)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(interval))
        timer.setEventHandler(handler: { [weak self] in
            self?.request({ result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    let handlerResult = self.handler?(data)
                    switch handlerResult {
                    case .success, .error:
                        self.endPoll()
                    case .none, .wait:
                        break
                    }

                    if let handlerResult = handlerResult {
                        self.notify?(self.requestId, handlerResult)
                    }
                case .failure:
                    self.endPoll()
                    self.notify?(self.requestId, .error())
                }
            })
        })
        return timer
    }
}

final class PollGroup<T: Decodable> {

    enum PollGroupResult {
        case allSuccess
        case someError
        case allError
    }

    typealias Handler = (PollGroupResult) -> Void

    private(set) var items: [PollService<T>] = []
    private(set) var isPolling: Bool = false
    private var results: [UUID: PollService<T>.HandlerResult] = [:]
    private let group = DispatchGroup()

    var didFinish: Handler?

    init() {}

    init(_ items: [PollService<T>]) {
        self.items = items
    }

    func add(_ item: PollService<T>) {
        guard !isPolling else { return }
        items.append(item)
    }

    func add(_ items: [PollService<T>]) {
        guard !isPolling else { return }
        self.items.append(contentsOf: items)
    }

    func startAll() {
        guard !isPolling else { return }

        isPolling = true
        items.forEach {
            group.enter()
            self.results[$0.requestId] = .wait
            $0.notify = {[weak self] requestId, result in
                self?.results[requestId] = result
                switch result {
                case .success, .error:
                    self?.group.leave()
                case .wait:
                    break

                }
            }
            $0.startPoll()
        }

        group.notify(queue: .main) { [weak self] in
            if let check = self?.check() {
                self?.didFinish?(check)
            }
        }
    }

    func endAll() {
        guard isPolling else { return }
        isPolling = false
        results = [:]
        items.forEach { $0.endPoll(); group.leave(); }
    }

    func reset() {
        isPolling = false
        results = [:]
        items.forEach {$0.endPoll(); group.leave(); }
        items = []
    }

    private func check() -> PollGroupResult? {
        let allSuccess = results.allSatisfy { (key, value) in
            switch value {
            case .success:
                return true
            case .error, .wait:
                return false
            }
        }
        
        if allSuccess {
            return .allSuccess
        }

        let allError = results.allSatisfy { (key, value) in
            switch value {
            case .success, .wait:
                return false
            case .error:
                return true
            }
        }
        if allError {
            return .allError
        }

        return .someError
    }
}
