//
//  PollingService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 18.04.2023.
//

import Foundation

final class PollService<T: Decodable> {

    typealias PollServiceRequest = (_ callback: @escaping (T) -> Void) -> Void

    private let request: PollServiceRequest
    private let operation = OperationQueue()
    private var timer: DispatchSourceTimer?
    private let interval: Int

    private(set) var isPolling: Bool = false

    var handler: ((T?) -> Void)?

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
                self?.handler?(result)
            })
        })
        return timer
    }
}
