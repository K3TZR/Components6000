//
//  ApiEffects.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/7/22.
//

import Foundation
import ComposableArchitecture
import Combine
import SwiftUI

import Discovery
import TcpCommands
import Shared

// ----------------------------------------------------------------------------
// MARK: - Public proerties

public enum ConnectionMode: String {
  case both
  case local
  case none
  case smartlink
}

public struct TcpMessage: Equatable, Identifiable {
  public var id = UUID()
  var direction: TcpMessageDirection
  var text: String
  var color: Color
  var timeInterval: TimeInterval
}

// ----------------------------------------------------------------------------
// MARK: - Internal methods

func sentMessages(_ tcp: Tcp) -> Effect<ApiAction, Never> {
  
  // subscribe to the publisher of sent TcpMessages
  tcp.sentPublisher
    .receive(on: DispatchQueue.main)
    // convert to TcpMessage format
    .map { tcpMessage in .tcpAction(TcpMessage(direction: tcpMessage.direction, text: tcpMessage.text, color: lineColor(tcpMessage.text), timeInterval: tcpMessage.timeInterval)) }
    .eraseToEffect()
    .cancellable(id: SentCommandSubscriptionId())
}

func receivedMessages(_ tcp: Tcp) -> Effect<ApiAction, Never> {
  
  // subscribe to the publisher of received TcpMessages
  tcp.receivedPublisher
    // eliminate replies unless they have errors or data
    .filter { allowToPass($0.text) }
    .receive(on: DispatchQueue.main)
    // convert to an ApiAction
    .map { tcpMessage in .tcpAction(TcpMessage(direction: tcpMessage.direction, text: tcpMessage.text, color: lineColor(tcpMessage.text), timeInterval: tcpMessage.timeInterval)) }
    .eraseToEffect()
    .cancellable(id: ReceivedCommandSubscriptionId())
}

func logAlerts() -> Effect<ApiAction, Never> {
  
  // subscribe to the publisher of LogEntries with Warning or Error levels
  LogProxy.sharedInstance.alertPublisher
    .receive(on: DispatchQueue.main)
    // convert to an ApiAction
    .map { logEntry in .logAlert(logEntry) }
    .eraseToEffect()
    .cancellable(id: LogAlertSubscriptionId())
}

// ----------------------------------------------------------------------------
// MARK: - Private methods

/// Assign each text line a color
/// - Parameter text:   the text line
/// - Returns:          a Color
private func lineColor(_ text: String) -> Color {
  if text.prefix(1) == "C" { return Color(.systemGreen) }                         // Commands
  if text.prefix(1) == "R" && text.contains("|0|") { return Color(.systemGray) }  // Replies no error
  if text.prefix(1) == "R" && !text.contains("|0|") { return Color(.systemRed) }  // Replies w/error
  if text.prefix(2) == "S0" { return Color(.systemOrange) }                       // S0
  
  return Color(.textColor)
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
