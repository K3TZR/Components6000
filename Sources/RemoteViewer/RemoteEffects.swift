//
//  RemoteEffects.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 3/29/22.
//

import Foundation
import ComposableArchitecture

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
        return .getRelaysCompleted(true, try! decoder.decode( IdentifiedArrayOf<Relay>.self, from: output.data))
        
      case .failure:
        return .getRelaysCompleted(false, IdentifiedArrayOf<Relay>())
      }
    }
    .eraseToEffect()
}

func getScripts(_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/source/")!)
  request.setBasicAuth(username: user, password: pwd)
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

func setScripts(_ scripts: String, _ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "X-CSRF": "x"
  ]
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/script/source/")!)
  request.setBasicAuth(username: user, password: pwd)
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

public func runScript(_ script: RelayScript,_ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  let parameters = [["user_function": script.type.rawValue as Any]]
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
        return .runScriptCompleted(script.duration, true, script)
        
      case .failure:
        return .runScriptCompleted(script.duration, false, script)
      }
    }
    .eraseToEffect()
}

func getProperty(_ property: RelayProperty, at index: Int?, _ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF": "x"
  ]
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/\(index == nil ? "all;" : String(index!))/\(property.rawValue)/")!)
  
  request.setBasicAuth(username: user, password: pwd)
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
        return .getPropertyCompleted(false, "\(property.rawValue) at index \(index == nil ? "all;" : String(index!))")
      }
    }
    .eraseToEffect()
}

func setProperty(_ property: RelayProperty, at index: Int?, value: String, _ user: String, _ pwd: String) -> Effect<RemoteAction, Never> {
  let headers = [
    "Connection": "close",
    "X-CSRF": "x"
  ]
  
  var request = URLRequest(url: URL(string: "https://192.168.1.220/restapi/relay/outlets/\(index == nil ? "all;" : String(index!))/\(property.rawValue)/")!)
  request.setBasicAuth(username: user, password: pwd)
  request.allHTTPHeaderFields = headers
  request.httpMethod = "PUT"
  request.httpBody = Data(value.utf8)
  
  return URLSession.DataTaskPublisher(request: request, session: .shared)
    .receive(on: DispatchQueue.main)
    .catchToEffect()
    .map { result in
      switch result {
      case .success(_):
        return .setPropertyCompleted(true, "set \(property) to: \(value) at: \(index == nil ? "all" : String(index!))" )
        
      case .failure:
        return .setPropertyCompleted(false, "set \(property) to: \(value) at: \(index == nil ? "all" : String(index!))" )
      }
    }
    .eraseToEffect()
}
