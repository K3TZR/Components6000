//
//  ApiSupport.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import SwiftUI

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

func listenForLocalPackets(_ state: ApiState) -> AlertView? {
  do {
    try state.discovery?.startLanListener()
    return nil
  } catch LanListenerError.kSocketError {
    return AlertView(title: "Discovery: Lan Listener, Failed to open a socket")
  } catch LanListenerError.kReceivingError {
    return AlertView(title: "Discovery: Lan Listener, Failed to start receiving")
  } catch {
    return AlertView(title: "Discovery: Lan Listener, unknown error")
  }
}

func listenForWanPackets(_ discovery: Discovery, using smartlinkEmail: String, forceLogin: Bool = false) -> AlertView? {
  do {
    try discovery.startWanListener(smartlinkEmail: smartlinkEmail, forceLogin: forceLogin)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertView(title: "Discovery: Wan Logoin required")
  } catch WanListenerError.kFailedToConnect {
    return AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    return AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}

func listenForWanPackets(_ discovery: Discovery, using loginResult: LoginResult) -> AlertView? {
  do {
    try discovery.startWanListener(using: loginResult)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertView(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
  } catch WanListenerError.kFailedToConnect {
    return AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    return AlertView(title: "Discovery: Wan Listener, unknown error")
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


