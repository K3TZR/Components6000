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
import Shared
//
//// ----------------------------------------------------------------------------
//// MARK: - Structs and Enums used by ApiViewer
//
//struct ReceivedMessagesSubscriptionId: Hashable {}
//struct SentMessagesSubscriptionId: Hashable {}
//struct LogAlertSubscriptionId: Hashable {}
//struct WanStatusSubscriptionId: Hashable {}
//struct ReceivedPacketSubscriptionId: Hashable {}
//
//public struct DefaultConnection: Codable, Equatable {
//
//  public init(_ selection: PickerSelection) {
//    self.source = selection.packet.source.rawValue
//    self.serial = selection.packet.serial
//    self.station = selection.station
//  }
//
//  public static func == (lhs: DefaultConnection, rhs: DefaultConnection) -> Bool {
//    guard lhs.source == rhs.source else { return false }
//    guard lhs.serial == rhs.serial else { return false }
//    guard lhs.station == rhs.station else { return false }
//    return true
//  }
//
//  var source: String
//  var serial: String
//  var station: String?
//
//  enum CodingKeys: String, CodingKey {
//    case source
//    case serial
//    case station
//  }
//}

// ----------------------------------------------------------------------------
// MARK: - Pure functions used by ApiCore

/// Start / Stop Listening for local packet broadcasts
/// - Parameters:
///   - mode:         mode (local, smartlink, both, none)
///   - discovery:    a reference to the Discovery object
/// - Returns:        an Alert or nil
//func startStopLanListener(_ mode: ConnectionMode, discovery: Discovery) -> AlertState<ApiAction>? {
//  switch mode {
//
//  case .both, .local: return startLanListener(discovery)
//  case .smartlink:
//      discovery.stopLanListener()
//      discovery.removePackets(ofType: .local)
//  case .none:
//    discovery.stopLanListener()
//    discovery.removePackets(ofType: .local)
//  }
//  return nil
//}

/// Start / Stop Listening for smartlink packet messages
/// - Parameters:
///   - mode:         mode (local, smartlink, both, none)
///   - discovery:    a reference to the Discovery object
///   - using:        the email address registered to smartlink
///   - forceLogin:   if set, force the user to login first
/// - Returns:        an Alert or nil
//func startStopWanListener(_ mode: ConnectionMode, discovery: Discovery, using smartlinkEmail: String, forceLogin: Bool = false) -> AlertState<ApiAction>? {
//  switch mode {
//
//  case .both, .smartlink: return startWanListener(discovery, using: smartlinkEmail, forceLogin: forceLogin)
//  case .local:
//      discovery.stopWanListener()
//      discovery.removePackets(ofType: .smartlink)
//  case .none:
//    discovery.stopWanListener()
//    discovery.removePackets(ofType: .smartlink)
//  }
//  return nil
//}

/// Start listening for local packet broadcasts
/// - Parameter discovery:   a reference to the Discovery object
/// - Returns:               an Alert or nil
//func startLanListener(_ discovery: Discovery) -> AlertState<ApiAction>? {
//  do {
//    try discovery.startLanListener()
//    return nil
//  } catch LanListenerError.kSocketError {
//    return AlertState(title: TextState("Discovery: Lan Listener, Failed to open a socket"))
//  } catch LanListenerError.kReceivingError {
//    return AlertState(title: TextState("Discovery: Lan Listener, Failed to start receiving"))
//  } catch {
//    return AlertState(title: TextState("Discovery: Lan Listener, unknown error"))
//  }
//}

/// Start listening for smartlink packet messages
/// - Parameter discovery:   a reference to the Discovery object
///   - using:                                     the email address registered to smartlink
///   - forceLogin:                             if set, force the user to login first
/// - Returns:               an Alert or nil
//func startWanListener(_ discovery: Discovery, using smartlinkEmail: String, forceLogin: Bool = false) -> AlertState<ApiAction>? {
//  do {
//    try discovery.startWanListener(smartlinkEmail: smartlinkEmail, forceLogin: forceLogin)
//    return nil
//  } catch WanListenerError.kFailedToObtainIdToken {
//    return AlertState(title: TextState("Discovery: Wan Login required"))
//  } catch WanListenerError.kFailedToConnect {
//    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Connect"))
//  } catch {
//    return AlertState(title: TextState("Discovery: Wan Listener, unknown error"))
//  }
//}

/// Start listening for smartlink packet messages
/// - Parameter discovery:   a reference to the Discovery object
///   - using:                                     the return value from a login attempt
/// - Returns:               an Alert or nil
//func startWanListener(_ discovery: Discovery, using loginResult: LoginResult) -> AlertState<ApiAction>? {
//  do {
//    try discovery.startWanListener(using: loginResult)
//    return nil
//  } catch WanListenerError.kFailedToObtainIdToken {
//    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Obtain IdToken"))
//  } catch WanListenerError.kFailedToConnect {
//    return AlertState(title: TextState("Discovery: Wan Listener, Failed to Connect"))
//  } catch {
//    return AlertState(title: TextState("Discovery: Wan Listener, unknown error"))
//  }
//}

