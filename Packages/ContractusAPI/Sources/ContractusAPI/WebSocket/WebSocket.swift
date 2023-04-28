//
//  WebSocket.swift
//  
//
//  Created by Simon Hudishkin on 28.04.2023.
//

import Foundation
import Combine

final public class WebSocket: NSObject {

    private var webSocket : URLSessionWebSocketTask!
    private var server: ServerType
    private var header: AuthorizationHeader
    private var isConnected: Bool = false
    private var allowReconnect: Bool = false
    private let decoder = JSONDecoder()
    
    public var disconnectHandler: (() -> Void)?

    private(set) var publisher: PassthroughSubject<SocketMessage, Never> = .init()

    public init(server: ServerType, header: AuthorizationHeader) {
        self.server = server
        self.header = header
        super.init()
    }

    public func update(header: AuthorizationHeader) {
        let wasConnected = isConnected
        disconnect()
        self.header = header
        if wasConnected {
            connect()
        }
    }

    public func connect() {
        guard !isConnected else { return }
        var request = URLRequest(url: server.wsURL)
        request.headers.add(header.value)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = session.webSocketTask(with: request)

        allowReconnect = true
        webSocket.resume()
    }

    public func disconnect() {
        allowReconnect = false
        guard isConnected else { return }
        webSocket.cancel(with: .goingAway, reason: nil)
    }

    private func ping() {
        webSocket.sendPing { [weak self] error in
            guard error == nil else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                self?.ping()
            }
        }
    }

    private func receive() {
        webSocket.receive(completionHandler: {[weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data:
                    debugPrint("Data received")
                case .string(let string):
                    guard let m = self?.decodeMessage(string: string) else { return }
                    DispatchQueue.main.async { [m] in
                        self?.publisher.send(m)
                    }
                default:
                    break
                }
            case .failure:
                break
            }
            self?.receive()
        })
    }

    private func decodeMessage(string: String) -> SocketMessage {
        (try? decoder.decode(SocketMessage.self, from: string.data(using: .utf8) ?? Data())) ?? .unknown(string)
    }
}

extension WebSocket: URLSessionWebSocketDelegate {

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.isConnected = true
        ping()
        receive()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.isConnected = false
        self.disconnectHandler?()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if (error as? NSError)?.code == -1004 {
            self.disconnect()
            return
        }
        guard allowReconnect, error != nil else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            self.connect()
        }
    }
}
