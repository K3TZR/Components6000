//
//  RemoteCore.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/26/22.
//

import Foundation
import ComposableArchitecture
import Combine

import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

struct RelaySubscriptionId: Hashable {}


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
  case getResult(Bool, String)
  case noAction
  case onAppear
  case refresh
  case relayLoadFailed
  case relaysReceived([Relay])
  case postResult(Bool, String)
  case cycleOn
  case cycleOff
//  case toggleCritical(Int)
//  case toggleState(Int)
//  case toggleLocked(Int)
//  case cycleDelayChanged(Int, String)
  
  case relay(id: Relay.ID, action: RelayAction)
}

public struct RemoteEnvironment {
  public init() {}
}

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let remoteReducer = Reducer<RemoteState, RemoteAction, RemoteEnvironment>.combine(
  relayReducer.forEach(
    state: \.relays,
    action: /RemoteAction.relay(id:action:),
    environment: { _ in RelayEnvironment() }
  ),
  Reducer { state, action, environment in
    
    switch action {
      // ----------------------------------------------------------------------------
      // MARK: - Initialization
      
    case .onAppear:
      return getRelays( "admin", "ruwn1viwn_RUF_zolt" )

      // ----------------------------------------------------------------------------
      // MARK: - RelayView UI actions
      
    case .allOff:
//      for (i, relay) in state.relays.enumerated() {
//        state.relays[i].state = false
//      }
////      return .none
//      return getName( "admin", "ruwn1viwn_RUF_zolt" )
      return setProperty("state", value: "false", at: nil, "admin", "ruwn1viwn_RUF_zolt" )
//      return .none
      
    case .refresh:
      return getRelays( "admin", "ruwn1viwn_RUF_zolt" )
    
//    case .toggleLocked(let index):
//      // permanently disabled
//      return .none
//
//    case .toggleState(let id):
//      state.relays[id: id].currentState.toggle()
//      return setProperty("state", value: state.relays[index].state.asTrueFalse.lowercased(), at: index, "admin", "ruwn1viwn_RUF_zolt")
//
//    case .toggleCritical(let id):
//      state.relays[id: id].critical.toggle()
//      return setProperty("critical", value: state.relays[index].critical.asTrueFalse.lowercased(), at: index, "admin", "ruwn1viwn_RUF_zolt")
    
    case .relaysReceived(let relays):
//      state.relays = relays
//      for (i, relay) in state.relays.enumerated() {
//        state.relays[i].cycleDelayString = state.relays[i].cycleDelay == nil ? "" : String(state.relays[i].cycleDelay!)
//      }
      state.forceUpdate.toggle()
      return .none
    
    case .relayLoadFailed:
      return .none

//    case .cycleDelayChanged(let index, let text):
//      print("cycleDelayChanged: index = \(index), value = \(text)")
////      state.relays[index].cycleDelay = currentValue
////      return setProperty("cycle_delay", value: valueString, at: index, "admin", "ruwn1viwn_RUF_zolt")
//      return .none
//
////    case .incrCycleDelay(let index):
////      var currentValue = state.relays[index].cycleDelay ?? 0
////      currentValue += 1
////      let valueString = String(currentValue)
////      print("INCR: valueString = \(valueString)")
////      state.relays[index].cycleDelay = currentValue
////      return setProperty("cycle_delay", value: valueString, at: index, "admin", "ruwn1viwn_RUF_zolt")

    case .cycleOn:
      state.scriptInFlight = true
      return sendScript( "cycle_on", "admin", "ruwn1viwn_RUF_zolt" )
    
    case .cycleOff:
      state.scriptInFlight = true
      return sendScript( "cycle_off", "admin", "ruwn1viwn_RUF_zolt" )

    case .getResult(let success, let value):
//      print( "-----> Get result, (\(success ? "success" : "failure")), value = \(value)" )
      sleep(4)
      state.scriptInFlight = false
//      return Effect(value: .refresh)
      return .none

    case .postResult(let success, let command):
      print( "-----> Post result, (\(success ? "success" : "failure")), command = \(command)" )
//      sleep(4)
      state.scriptInFlight = false
//      return Effect(value: .refresh)
      return .none
      
    case .noAction:
      // this is a placeholder, it should never happen
//      fatalError("noAction occurred")
      return .none
      
    case .relay(let id, let action):
      return .none
    }
  }
  )


// ----------------------------------------------------------------------------
// MARK: - Helper functions

public var initialRelays: IdentifiedArrayOf<Relay> = [
  Relay(critical: true, transientState: true, physicalState: true, currentState: true, name: "Relay 0", locked: true),
  Relay(critical: false, transientState: true, physicalState: true, currentState: true, name: "Relay 1", locked: false),
  Relay(name: "Relay 2"),
  Relay(name: "Relay 3"),
  Relay(name: "Relay 4"),
  Relay(critical: false, transientState: false, physicalState: false, currentState: false, name: "Relay 5", locked: false),
  Relay(name: "Relay 6"),
  Relay(name: "Relay 7")
]

extension URLRequest {
  mutating func setBasicAuth(username: String, password: String) {
    let encodedAuthInfo = String(format: "%@:%@", username, password)
      .data(using: String.Encoding.utf8)!
      .base64EncodedString()
    addValue("Basic \(encodedAuthInfo)", forHTTPHeaderField: "Authorization")
  }
}

func getRelays(_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/")!)
  request.setBasicAuth(username: user, password: pwd)
  request.httpMethod = "GET"
  request.allHTTPHeaderFields = headers

  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return .relaysReceived(try! decoder.decode([Relay].self, from: output.data))
        
      case .failure:
        return .relayLoadFailed
      }
    }
    .eraseToEffect()
}

func setRelays(_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  let parameters = [[
    "state": true,
    "critical": false,
    "cycle_delay": 10,
    "locked": false,
    "transient_state": false,
    "physical_state": true,
    "name": "This is a relay"
  ]] as [[String : Any]]
  
  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])

  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/1/")!)
  request.setBasicAuth(username: user, password: pwd)
  request.httpMethod = "PUT"
  request.allHTTPHeaderFields = headers
  request.httpBody = postData as Data

  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        print( String(decoding: output.data, as: UTF8.self))
        return .postResult(true, "setRelays")
        
      case .failure:
        return .postResult(false, "setRelays")
      }
    }
    .eraseToEffect()
}



func getName(_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
//  let headers = [
//    "Connection": "close",
//    "Content-Type": "application/json",
//    "Accept": "application/json",
//    "X-CSRF": "x"
//  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/0/name/")!)
  
  let authData = (user + ":" + pwd).data(using: .utf8)!.base64EncodedString()
  request.addValue("Basic \(authData)", forHTTPHeaderField: "Authorization")

  request.addValue("close", forHTTPHeaderField: "Connection")
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.addValue("close", forHTTPHeaderField: "Connection")
  request.addValue("x", forHTTPHeaderField: "X-CSRF")

  request.httpMethod = "GET"

  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return .getResult(true, String(decoding: output.data, as: UTF8.self))

      case .failure:
        return .getResult(false, "")
      }
    }
    .eraseToEffect()
}

func setProperty(_ property: String, value: String, at index: Int?, _ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
//  let headers = [
//    "Connection": "close",
//    "Content-Type": "application/json",
//    "Accept": "application/json",
//    "X-CSRF": "x"
//  ]
//  let parameters = [["value":"Some other relay"]]
//  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
  let postData = value.data(using: String.Encoding.utf8)!

  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/\(index == nil ? "all;" :  String(index!))/\(property)/")!)
  let authData = (user + ":" + pwd).data(using: .utf8)!.base64EncodedString()
  request.addValue("Basic \(authData)", forHTTPHeaderField: "Authorization")

  request.addValue("close", forHTTPHeaderField: "Connection")
  request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
//  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.addValue("close", forHTTPHeaderField: "Connection")
  request.addValue("x", forHTTPHeaderField: "X-CSRF")

  request.httpMethod = "PUT"

  request.httpBody = postData
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        print( String(decoding: output.data, as: UTF8.self))

        return .postResult(true, "set \(property) to: \(value) at: \(index == nil ? "all" : String(index!))" )

      case .failure:
        return .postResult(false, "set \(property) to: \(value) at: \(index == nil ? "all" : String(index!))" )
      }
    }
    .eraseToEffect()
}









//func setRelays2(_ user: String, _ pwd: String) {
//  //
//  // Sample for relay object / outlets[].
//  //
//  // This is a sample demonstrating how to set the outlet.
//  //
//
//  // Note that this sample has been generated by httpsnippet;
//  // authentication configuration (usually digest) is not included.
//
//  let headers = [
//    "Connection": "close",
//    "Content-Type": "application/json",
//    "Accept": "application/json",
//    "X-CSRF": "x"
//  ]
//  let parameters = [
//    "state": false,
//    "critical": true,
//    "cycle_delay": 8,
//    "locked": false,
//    "transient_state": false,
//    "physical_state": true,
//    "name": "POE Injector"
//  ] as [String : Any]
//
//  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
//
//  let request = NSMutableURLRequest(url: NSURL(string: "https://192.168.1.220/restapi/relay/outlets/1/")! as URL,
//                                          cachePolicy: .useProtocolCachePolicy,
//                                      timeoutInterval: 10.0)
//  request.setBasicAuth(username: user, password: pwd)
//  request.httpMethod = "PUT"
//  request.allHTTPHeaderFields = headers
//  request.httpBody = postData as Data
//
//  let session = URLSession.shared
//  let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
//    if (error != nil) {
//      print(error)
//    } else {
//      let httpResponse = response as? HTTPURLResponse
//      print(httpResponse)
//      print( String(decoding: data!, as: UTF8.self))
//
//    }
//  })
//
//  dataTask.resume()
//
//
//  // Sample result:
//  //
//
//
//}

//public func scriptRequest(_ script: String, _ user: String, _ pwd: String) -> URLRequest {
//
//  let headers = [
//    "Connection": "close",
//    "Content-Type": "application/json",
//    "Accept": "application/json",
//    "X-CSRF": "x"
//  ]
//  let parameters = [["user_function": script as Any]]
//  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
//
//  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/start/")!)
//  request.setBasicAuth(username: user, password: pwd)
//
//  request.httpMethod = "POST"
//  request.allHTTPHeaderFields = headers
//  request.httpBody = postData as Data
//  return request
//}

public func sendScript(_ script: String, _ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {

  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  let parameters = [["user_function": script as Any]]
  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/start/")!)
  request.setBasicAuth(username: user, password: pwd)
  request.httpMethod = "POST"
  request.allHTTPHeaderFields = headers
  request.httpBody = postData as Data

  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .postResult(true, script)
        
      case .failure:
        return .postResult(false, script)
      }
    }
    .eraseToEffect()
}

func reboot(_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/system/reboot/")!)
  request.setBasicAuth(username: user, password: pwd)

  request.httpMethod = "POST"
  request.allHTTPHeaderFields = headers

  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .postResult(true, "reboot")
        
      case .failure:
        return .postResult(false, "reboot")
      }
    }
    .eraseToEffect()
}
