//
//  RelayCore.swift
//  Components6000/DinRelay
//
//  Created by Douglas Adams on 2/26/22.
//

import Foundation
import ComposableArchitecture
import Combine

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

struct RelaySubscriptionId: Hashable {}

public struct Relay: Codable, Equatable {
  
  public init(
    critical: Bool = false,
    transientState: Bool = false,
    physicalState: Bool = false,
    state: Bool = false,
    name: String,
    cycleDelay: Int? = nil,
    locked: Bool = false
  ) {
    self.critical = critical
    self.transientState = transientState
    self.physicalState = physicalState
    self.state = state
    self.name = name
    self.cycleDelay = cycleDelay
    self.locked = locked
  }
  public var critical: Bool
  public var transientState: Bool
  public var physicalState: Bool
  public var state: Bool
  public var name: String
  public var cycleDelay: Int?
  public var locked: Bool
}

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct RemoteState: Equatable {
  
  public init(_ heading: String = "Relay Status") {
    self.heading = heading
  }
  public var heading: String
  public var relays = initialRelays
  public var forceUpdate = false
}

public enum RemoteAction: Equatable {
  case allOff
  case onAppear
  case refresh
  case relayLoadFailed
  case relaysReceived([Relay])
  case start
  case stop
  case toggleState(Int)
  case toggleLocked(Int)
}

public struct RemoteEnvironment {
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let remoteReducer = Reducer<RemoteState, RemoteAction, RemoteEnvironment>
  { state, action, environment in
    
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      return getRelays( relayRequest("admin", "ruwn1viwn_RUF_zolt") )

      // ----------------------------------------------------------------------------
      // MARK: - RelayView UI actions
      
    case .allOff:
      print("-----> All Off")
      for (i, relay) in state.relays.enumerated() {
        state.relays[i].state = false
      }
      return .none
      
    case .refresh:
      return getRelays( relayRequest("admin", "ruwn1viwn_RUF_zolt") )
    
    case .toggleLocked(let index):
      state.relays[index].locked.toggle()
      return .none

    case .toggleState(let index):
      state.relays[index].state.toggle()
      return .none
    
    case .relaysReceived(let relays):
      state.relays = relays
      state.forceUpdate.toggle()
      return .none
    
    case .relayLoadFailed:
      return .none
    
    case .start:
      return .none
    
    case .stop:
      return .none
    }
  }


// ----------------------------------------------------------------------------
// MARK: - Helper functions

public var initialRelays = [
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized"),
  Relay(name: "uninitialized")
]

extension URLRequest {
  mutating func setBasicAuth(username: String, password: String) {
    let encodedAuthInfo = String(format: "%@:%@", username, password)
      .data(using: String.Encoding.utf8)!
      .base64EncodedString()
    addValue("Basic \(encodedAuthInfo)", forHTTPHeaderField: "Authorization")
    addValue("x", forHTTPHeaderField: "X-CSRF")
  }
}

func relayRequest(_ user: String, _ pwd: String) -> URLRequest {
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/")!)
  request.setBasicAuth(username: user, password: pwd)
  request.httpMethod = "GET"
  return request
}

func getRelays(_ request: URLRequest) -> Effect<RemoteAction, Never> {
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return .relaysReceived(try! decoder.decode([Relay].self, from: output.data))
        
      case .failure:
        return .relayLoadFailed
      }
    }
    .eraseToEffect()
}
