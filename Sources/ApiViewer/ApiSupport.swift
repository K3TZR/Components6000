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
import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums used by ApiViewer

struct CommandSubscriptionId: Hashable {}

public struct DefaultConnection: Codable, Equatable {

  public static func == (lhs: DefaultConnection, rhs: DefaultConnection) -> Bool {
    guard lhs.source == rhs.source else { return false }
    guard lhs.publicIp == rhs.publicIp else { return false }
    return true
  }

  var source: String
  var publicIp: String
  var clientIndex: Int?

  enum CodingKeys: String, CodingKey {
    case source
    case publicIp
    case clientIndex
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
}

// ----------------------------------------------------------------------------
// MARK: - Pure functions used by ApiViewer

func listenForPackets(_ state: inout ApiState) {
  if state.discovery == nil { state.discovery = Discovery.sharedInstance }
  if state.connectionMode == .local || state.connectionMode == .both {
    do {
      try state.discovery?.startLanListener()

    } catch LanListenerError.kSocketError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to open a socket")
    } catch LanListenerError.kReceivingError {
      state.alert = AlertView(title: "Discovery: Lan Listener, Failed to start receiving")
    } catch {
      state.alert = AlertView(title: "Discovery: Lan Listener, unknown error")
    }
  }
  if state.connectionMode == .smartlink || state.connectionMode == .both {
    do {
      try state.discovery?.startWanListener(smartlinkEmail: state.smartlinkEmail, force: state.wanLogin)

    } catch WanListenerError.kFailedToObtainIdToken {
      state.loginState = LoginState(email: state.smartlinkEmail)

    } catch WanListenerError.kFailedToConnect {
      state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
    } catch {
      state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
    }
  }
}

func listenForWanPackets(_ state: inout ApiState, loginResult: LoginResult) {
  state.smartlinkEmail = loginResult.email
  state.loginState = nil
  do {
    try state.discovery?.startWanListener(using: loginResult)

  } catch WanListenerError.kFailedToObtainIdToken {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Obtain IdToken")
  } catch WanListenerError.kFailedToConnect {
    state.alert = AlertView(title: "Discovery: Wan Listener, Failed to Connect")
  } catch {
    state.alert = AlertView(title: "Discovery: Wan Listener, unknown error")
  }
}

func identifyDefault(_ conn: DefaultConnection?, _ discovery: Discovery) -> Packet? {
  guard conn != nil else { return nil }
  for packet in discovery.packets where conn!.source == packet.source.rawValue && conn!.publicIp == packet.publicIp {
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
