//
//  Channel+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation
import SwiftPhoenixClient

extension Channel {
    
    func join<T: Decodable, E: Decodable>(with decoder: JSONDecoder = .init(), perform: @escaping (Result<T, E>) -> Void) {
        self
            .join()
            .receive("ok", with: decoder) { (result: Result<T, Error>) in
                switch result {
                case .success(let payload):
                    perform(.success(payload))
                case .failure(let error):
                    print("Error decoding payload for join with status ok:", String(describing: error))
                }
            }
            .receive("error", with: decoder) { (result: Result<E, Error>) in
                switch result {
                case .success(let payload):
                    perform(.failure(payload))
                case .failure(let error):
                    print("Error decoding payload for join with status error:", String(describing: error))
                }
            }
    }
    
    func on<T: Decodable>(_ event: GameEvent, with decoder: JSONDecoder = .init(), perform: @escaping (T) -> Void) {
        self.on(event.rawValue, callback: { message in
            do {
                let data = try JSONSerialization.data(withJSONObject: message.payload)
                let decoded = try decoder.decode(T.self, from: data)
                perform(decoded)
            } catch(let error) {
                print("Error decoding payload for \(event):", String(describing: error))
            }
        })
    }
    
    @discardableResult
    func push(_ event: GameEvent, payload: Payload) -> Push {
        self.push(event.rawValue, payload: payload)
    }
    
    @discardableResult
    func push<T: Decodable, E: Decodable>(_ event: GameEvent, payload: Payload, with decoder: JSONDecoder = .init(), perform: @escaping (Result<T, E>) -> Void) -> Push {
        self
            .push(event.rawValue, payload: payload)
            .receive("ok", with: decoder) { (result: Result<T, Error>) in
                switch result {
                case .success(let payload):
                    perform(.success(payload))
                case .failure(let error):
                    print("Error decoding payload received after successfully pushing \(event):", String(describing: error))
                }
            }
            .receive("error", with: decoder) { (result: Result<E, Error>) in
                switch result {
                case .success(let payload):
                    perform(.failure(payload))
                case .failure(let error):
                    print("Error decoding payload received after failure to push \(event):", String(describing: error))
                }
            }
    }
    
}

extension Push {
    
    @discardableResult
    func receive<T: Decodable, E: Decodable>(with decoder: JSONDecoder = .init(), perform: @escaping (Result<T, E>) -> Void) -> Push {
        self
            .receive("ok", with: decoder) { (result: Result<T, Error>) in
                switch result {
                case .success(let payload):
                    perform(.success(payload))
                case .failure(let error):
                    print("Error decoding payload for join with status ok:", String(describing: error))
                }
            }
            .receive("error", with: decoder) { (result: Result<E, Error>) in
                switch result {
                case .success(let payload):
                    perform(.failure(payload))
                case .failure(let error):
                    print("Error decoding payload for join with status error:", String(describing: error))
                }
            }
    }
    
    @discardableResult
    func receive<T: Decodable>(_ status: String, with decoder: JSONDecoder = .init(), perform: @escaping (Result<T, Error>) -> Void) -> Push {
        self.receive(status) { message in
            do {
                var data: Data
                if status == "error",
                   message.payload["status"] as? String == "error",
                   let response = message.payload["response"] as? String,
                   message.payload.keys.count == 2 {
                    data = "\"\(response)\"".data(using: .utf8)!
                } else {
                    data = try JSONSerialization.data(withJSONObject: message.payload)
                }
                
                let decoded = try decoder.decode(T.self, from: data)
                perform(.success(decoded))
            } catch (let error) {
                print("Error decoding payload received from push with status \(status):", String(describing: error))
                perform(.failure(error))
            }
        }
    }
    
}
