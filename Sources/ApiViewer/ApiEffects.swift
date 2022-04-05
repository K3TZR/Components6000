//
//  ApiEffects.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 3/21/22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

import TcpCommands
import Radio
import Shared

// ----------------------------------------------------------------------------
// MARK: - Subscriptions to publishers

// cancellation IDs
struct PacketSubscriptionId: Hashable {}
struct ClientSubscriptionId: Hashable {}
struct WanSubscriptionId: Hashable {}
struct ReceivedSubscriptionId: Hashable {}
struct SentSubscriptionId: Hashable {}
struct LogAlertSubscriptionId: Hashable {}
struct MeterSubscriptionId: Hashable {}

func subscribeToPackets() -> Effect<ApiAction, Never> {
  Effect.merge(
    Discovered.sharedInstance.packetPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .packetChangeReceived(update) }
      .eraseToEffect()
      .cancellable(id: PacketSubscriptionId()),
    
    Discovered.sharedInstance.clientPublisher
      .receive(on: DispatchQueue.main)
      .map { update in .clientChangeReceived(update) }
      .eraseToEffect()
      .cancellable(id: ClientSubscriptionId())
  )
}

func subscribeToWan() -> Effect<ApiAction, Never> {
  Effect(
    Discovered.sharedInstance.wanStatusPublisher
      .receive(on: DispatchQueue.main)
      .map { status in .wanStatus(status) }
      .eraseToEffect()
      .cancellable(id: WanSubscriptionId())
  )
}

func subscribeToSent(_ tcp: Tcp) -> Effect<ApiAction, Never> {
  // subscribe to the publisher of sent TcpMessages
  tcp.sentPublisher
    .receive(on: DispatchQueue.main)
    // convert to TcpMessage format
    .map { tcpMessage in .tcpMessage(TcpMessage(direction: tcpMessage.direction, text: tcpMessage.text, color: Color(.systemGreen), timeInterval: tcpMessage.timeInterval)) }
    .eraseToEffect()
    .cancellable(id: SentSubscriptionId())
}

func subscribeToReceived(_ tcp: Tcp) -> Effect<ApiAction, Never> {
  // subscribe to the publisher of received TcpMessages
  tcp.receivedPublisher
    // eliminate replies unless they have errors or data
    .filter { allowToPass($0.text) }
    .receive(on: DispatchQueue.main)
    // convert to an ApiAction
    .map { tcpMessage in .tcpMessage(TcpMessage(direction: tcpMessage.direction, text: tcpMessage.text, color: messageColor(tcpMessage.text), timeInterval: tcpMessage.timeInterval)) }
    .eraseToEffect()
    .cancellable(id: ReceivedSubscriptionId())
}

/// Received data Filter condition
/// - Parameter text:    the text of a received command
/// - Returns:           a boolean
private func allowToPass(_ text: String) -> Bool {
  if text.first != "R" { return true }     // pass if not a Reply
  let parts = text.components(separatedBy: "|")
  if parts.count < 3 { return true }        // pass if incomplete
  if parts[1] != kNoError { return true }   // pass if error of some type
  if parts[2] != "" { return true }         // pass if additional data present
  return false                              // otherwise, filter out (i.e. don't pass)
}

/// Assign each text line a color
/// - Parameter text:   the text line
/// - Returns:          a Color
private func messageColor(_ text: String) -> Color {
//  if text.prefix(1) == "C" { return Color(.systemGreen) }                         // Commands
  if text.prefix(1) == "R" && text.contains("|0|") { return Color(.systemGray) }  // Replies no error
  if text.prefix(1) == "R" && !text.contains("|0|") { return Color(.systemRed) }  // Replies w/error
  if text.prefix(2) == "S0" { return Color(.systemOrange) }                       // S0

  return Color(.textColor)
}

func subscribeToLogAlerts() -> Effect<ApiAction, Never> {
//  #if DEBUG
  // subscribe to the publisher of LogEntries with Warning or Error levels
  LogProxy.sharedInstance.alertPublisher
    .receive(on: DispatchQueue.main)
    // convert to an ApiAction
    .map { logEntry in .logAlertReceived(logEntry) }
    .eraseToEffect()
    .cancellable(id: LogAlertSubscriptionId())
//  #else
//    .empty
//  #endif
}

func subscribeToMeters() -> Effect<ApiAction, Never> {
  // subscribe to the publisher of received TcpMessages
  Meter.meterPublisher
    .receive(on: DispatchQueue.main)
    // limit updates to 1 per second
    .throttle(for: 1.0, scheduler: RunLoop.main, latest: true)
    // convert to an ApiAction
    .map { meter in .meterReceived(meter) }
    .eraseToEffect()
    .cancellable(id: MeterSubscriptionId())
}
