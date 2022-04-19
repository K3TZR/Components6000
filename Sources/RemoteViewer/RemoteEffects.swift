//
//  RemoteEffects.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 3/29/22.
//

import Foundation
import ComposableArchitecture
import CombineSchedulers

func getRelays( _ state: RemoteState ) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/")!)
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.httpMethod = "GET"
  request.allHTTPHeaderFields = headers
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        let decoder = JSONDecoder()
        return .getRelaysCompleted(true, try! decoder.decode( IdentifiedArrayOf<Relay>.self, from: output.data))
        
      case .failure:
        return .getRelaysCompleted(false, IdentifiedArrayOf<Relay>())
      }
    }
    .eraseToEffect()
}






// EXPERIMENTAL ASYNC VERSION
func getRelaysAsync( _ state: RemoteState ) -> Effect<RemoteAction, Never> {
  return Effect.task { () -> RemoteAction in
    let headers = [
      "Connection": "close",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF": "x"
    ]
    var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/")!)
    request.setBasicAuth(username: state.user, password: state.pwd!)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    let (data, response) = try! await URLSession.shared.data(for: request)
    print( try! JSONDecoder().decode( IdentifiedArrayOf<Relay>.self, from: data) )
    return RemoteAction.getRelaysCompleted(true,  try! JSONDecoder().decode( IdentifiedArrayOf<Relay>.self, from: data) )
  }
  .receive(on: DispatchQueue.main)
  .eraseToEffect()
}
  





func getScripts(_ state: RemoteState) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/source/")!)
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.httpMethod = "GET"
  request.allHTTPHeaderFields = headers
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        return .getScriptsCompleted(true, String(decoding: output.data, as: UTF8.self))
        
      case .failure:
        return .getScriptsCompleted(false, "")
      }
    }
    .eraseToEffect()
}

func setScripts(_ state: RemoteState, scripts: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "X-CSRF": "x"
  ]
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/source/")!)
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.allHTTPHeaderFields = headers
  request.httpMethod = "PUT"
  request.httpBody = Data(scripts.utf8)
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .setScriptsCompleted(true)
        
      case .failure:
        return .setScriptsCompleted(false)
      }
    }
    .eraseToEffect()
}

public func runScript(_ state: RemoteState, script: RelayScript) -> Effect<RemoteAction, Never> {
  
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  let parameters = [["user_function": script.type.rawValue as Any]]
  let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/start/")!)
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.httpMethod = "POST"
  request.allHTTPHeaderFields = headers
  request.httpBody = postData as Data
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .delay(for: DispatchQueue.SchedulerTimeType.Stride(floatLiteral: Double(script.duration)), scheduler: DispatchQueue.main)
    .map { result in
      switch result {
      case .success(_):
        return .runScriptCompleted(true, script)
        
      case .failure:
        return .runScriptCompleted(false, script)
      }
    }
    .eraseToEffect()
}

func getProperty(_ state: RemoteState, property: RelayProperty, at id: UUID?) -> Effect<RemoteAction, Never> {

  let index = id == nil ? "all;" : String(state.relays.index(id: id!)!)

  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/\(index)/\(property.rawValue)/")!)
  
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.allHTTPHeaderFields = headers
  request.httpMethod = "GET"
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(let output):
        print( String(decoding: output.data, as: UTF8.self))
        return .getPropertyCompleted(true, String(decoding: output.data, as: UTF8.self))
        
      case .failure:
        return .getPropertyCompleted(false, "\(property.rawValue) at index \(index)")
      }
    }
    .eraseToEffect()
}

func setProperty(_ state: RemoteState, property: RelayProperty, at id: UUID?, value: String) -> Effect<RemoteAction, Never> {
  
  
  let index = id == nil ? "all;" : String(state.relays.index(id: id!)!)
  
  let headers = [
    "Connection": "close",
    "X-CSRF": "x"
  ]
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/\(index)/\(property.rawValue)/")!)
  request.setBasicAuth(username: state.user, password: state.pwd!)
  request.allHTTPHeaderFields = headers
  request.httpMethod = "PUT"
  request.httpBody = Data(value.utf8)
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .setPropertyCompleted(true, "set \(property) to: \(value) at: \(index)" )
        
      case .failure:
        return .setPropertyCompleted(false, "set \(property) to: \(value) at: \(index)" )
      }
    }
    .eraseToEffect()
}

extension URLRequest {
  mutating func setBasicAuth(username: String, password: String) {
    let encodedAuthInfo = String(format: "%@:%@", username, password)
      .data(using: String.Encoding.utf8)!
      .base64EncodedString()
    addValue("Basic \(encodedAuthInfo)", forHTTPHeaderField: "Authorization")
  }
}
