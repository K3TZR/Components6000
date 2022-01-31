//
//  ApiSupport.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import SwiftUI
import ComposableArchitecture

import Login
import Discovery
import Picker
import UdpStreams
import Shared
import TcpCommands

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums used by ApiViewer

struct CommandSubscriptionId: Hashable {}

public struct DefaultConnection: Codable, Equatable {

  public init(_ selection: PickerSelection) {
    self.source = selection.packet.source.rawValue
    self.serial = selection.packet.serial
    self.station = selection.station
  }

  public static func == (lhs: DefaultConnection, rhs: DefaultConnection) -> Bool {
    guard lhs.source == rhs.source else { return false }
    guard lhs.serial == rhs.serial else { return false }
    guard lhs.station == rhs.station else { return false }
    return true
  }

  var source: String
  var serial: String
  var station: String?

  enum CodingKeys: String, CodingKey {
    case source
    case serial
    case station
  }
}

public enum ConnectionMode: String {
  case local
  case smartlink
  case both
}

public struct Message: Equatable, Identifiable {
  public var id = UUID()
  var direction: TcpMessageDirection
  var text: String
  var color: Color
  var timeInterval: TimeInterval
}

// ----------------------------------------------------------------------------
// MARK: - Pure functions used by ApiViewer

func startStopLanListener(_ mode: ConnectionMode, discovery: Discovery) -> AlertState<ApiAction>? {
  switch mode {
    
  case .both, .local: return startLanListener(discovery)
  case .smartlink:
      discovery.stopLanListener()
      discovery.removePackets(ofType: .local)
  }
  return nil
}

func startStopWanListener(_ mode: ConnectionMode, discovery: Discovery, using smartlinkEmail: String, forceLogin: Bool = false) -> AlertState<ApiAction>? {
  switch mode {
    
  case .both, .smartlink: return startWanListener(discovery, using: smartlinkEmail, forceLogin: forceLogin)
  case .local:
      discovery.stopWanListener()
      discovery.removePackets(ofType: .smartlink)
  }
  return nil
}


func startLanListener(_ discovery: Discovery) -> AlertState<ApiAction>? {
  do {
    try discovery.startLanListener()
    return nil
  } catch LanListenerError.kSocketError {
    return AlertState(title: TextState("Discovery: Lan Listener, Failed to open a socket"))
  } catch LanListenerError.kReceivingError {
    return AlertState(title: TextState("Discovery: Lan Listener, Failed to start receiving"))
  } catch {
    return AlertState(title: TextState("Discovery: Lan Listener, unknown error"))
  }
}

func startWanListener(_ discovery: Discovery, using smartlinkEmail: String, forceLogin: Bool = false) -> AlertState<ApiAction>? {
  do {
    try discovery.startWanListener(smartlinkEmail: smartlinkEmail, forceLogin: forceLogin)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertState(title: TextState("Discovery: Wan Logoin required"))
  } catch WanListenerError.kFailedToConnect {
    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Connect"))
  } catch {
    return AlertState(title: TextState("Discovery: Wan Listener, unknown error"))
  }
}

func startWanListener(_ discovery: Discovery, using loginResult: LoginResult) -> AlertState<ApiAction>? {
  do {
    try discovery.startWanListener(using: loginResult)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Obtain IdToken"))
  } catch WanListenerError.kFailedToConnect {
    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Connect"))
  } catch {
    return AlertState(title: TextState("Discovery: Wan Listener, unknown error"))
  }
}

func getDefaultConnection() -> DefaultConnection? {
  if let defaultData = UserDefaults.standard.object(forKey: "defaultConnection") as? Data {
    let decoder = JSONDecoder()
    if let defaultConnection = try? decoder.decode(DefaultConnection.self, from: defaultData) {
      return defaultConnection
    } else {
      return nil
    }
  }
  return nil
}

func setDefaultConnection(_ conn: DefaultConnection?) {
  if conn == nil {
    UserDefaults.standard.removeObject(forKey: "defaultConnection")
  } else {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(conn) {
      UserDefaults.standard.set(encoded, forKey: "defaultConnection")
    } else {
      UserDefaults.standard.removeObject(forKey: "defaultConnection")
    }
  }
}


