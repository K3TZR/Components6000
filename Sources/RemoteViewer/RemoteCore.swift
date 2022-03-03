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
  public var scriptInFlight = false
}

public enum RemoteAction: Equatable {
  case allOff
  case onAppear
  case refresh
  case relayLoadFailed
  case relaysReceived([Relay])
  case scriptSent(Bool)
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
      return getRelays( relayRequest("https://192.168.1.220/restapi/relay/outlets/", "admin", "ruwn1viwn_RUF_zolt") )

      // ----------------------------------------------------------------------------
      // MARK: - RelayView UI actions
      
    case .allOff:
      for (i, relay) in state.relays.enumerated() {
        state.relays[i].state = false
      }
      return .none
      
    case .refresh:
      return getRelays( relayRequest("https://192.168.1.220/restapi/relay/outlets/", "admin", "ruwn1viwn_RUF_zolt") )
    
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
      state.scriptInFlight = true
      return sendScript( scriptRequest("cycle_on", "https://192.168.1.220/restapi/script/start/", "admin", "ruwn1viwn_RUF_zolt"))
    
    case .stop:
      state.scriptInFlight = true
      return sendScript( scriptRequest("cycle_off", "https://192.168.1.220/restapi/script/start/", "admin", "ruwn1viwn_RUF_zolt"))

    case .scriptSent(let result):
      state.scriptInFlight = false
      print("-----> Script send, \(result ? "success" : "failure")")
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
  }
}

func relayRequest(_ url: String, _ user: String, _ pwd: String) -> URLRequest {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: url)!)
  request.setBasicAuth(username: user, password: pwd)

  request.httpMethod = "GET"
  request.allHTTPHeaderFields = headers
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

public func scriptRequest(_ script: String, _ url: String, _ user: String, _ pwd: String) -> URLRequest {
  
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  let parameters = [["user_function": script as Any]]
  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
  
  var request = URLRequest(url: URL(string: url)!)
  request.setBasicAuth(username: user, password: pwd)
  
  request.httpMethod = "POST"
  request.allHTTPHeaderFields = headers
  request.httpBody = postData as Data
  return request
}

public func sendScript(_ request: URLRequest) -> Effect<RemoteAction, Never> {
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .scriptSent(true)
        
      case .failure:
        return .scriptSent(false)
      }
    }
    .eraseToEffect()
}

// "https://192.168.1.220/restapi/script/start/"
