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
import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums used by ApiViewer

struct CommandSubscriptionId: Hashable {}

public struct DefaultConnection: Codable, Equatable {

  public init(_ selection: PickerSelection) {
    self.source = selection.source.rawValue
    self.serial = selection.serial
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

public struct CommandMessage: Equatable, Identifiable {
  public var id = UUID()
  var text: Substring
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

func listenForWanPackets(_ state: ApiState) -> AlertView? {
  do {
    try state.discovery?.startWanListener(smartlinkEmail: state.smartlinkEmail, force: state.wanLogin)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertView(title: "Discovery: Wan Logoin required")
  } catch WanListenerError.kFailedToConnect {
    return AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    return AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}

func listenForWanPackets(_ state: ApiState, using loginResult: LoginResult) -> AlertView? {
  do {
    try state.discovery?.startWanListener(using: loginResult)
    return nil
  } catch WanListenerError.kFailedToObtainIdToken {
    return AlertView(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
  } catch WanListenerError.kFailedToConnect {
    return AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    return AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}

func identifySelection(_ sel: PickerSelection?, _ discovery: Discovery) -> Packet? {
  guard sel != nil else { return nil }
  for packet in discovery.packets where sel!.source == packet.source && sel!.serial == packet.serial {
    return packet
  }
  return nil
}

func identifyDefault(_ conn: DefaultConnection?, _ discovery: Discovery) -> Packet? {
  guard conn != nil else { return nil }
  for packet in discovery.packets where conn!.source == packet.source.rawValue && conn!.serial == packet.serial {
    return packet
  }
  return nil
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

//func filterMessages(_ messages: IdentifiedArrayOf<CommandMessage>, ) -> IdentifiedArrayOf<CommandMessage> {
//
//  // get all except the first character
//  let suffix = String(text.dropFirst())
//
//  // switch on the first character
//  switch text[text.startIndex] {
//
//  case "C":   DispatchQueue.main.async { self.populateMessages(text) }      // Commands
//  case "H":   DispatchQueue.main.async { self.populateMessages(text) }      // Handle type
//  case "M":   DispatchQueue.main.async { self.populateMessages(text) }      // Message Type
//  case "R":   DispatchQueue.main.async { self.parseReplyMessage(suffix) }   // Reply Type
//  case "S":   DispatchQueue.main.async { self.populateMessages(text) }      // Status type
//  case "V":   DispatchQueue.main.async { self.populateMessages(text) }      // Version Type
//  default:    DispatchQueue.main.async { self.populateMessages("Tester: Unknown Message type, \(text[text.startIndex]) ") } // Unknown Type
//  }
//}
