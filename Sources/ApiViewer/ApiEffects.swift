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

import TcpCommands
import Shared

public func receiveMessagesEffect(_ command: TcpCommand) -> Effect<ApiAction, Never> {

  // subscribe to the publisher of received TcpMessages
  command.commandPublisher
    // eliminate replies without errors or data
    .filter { allowToPass($0.text) }
    .receive(on: DispatchQueue.main)
    // convert to CommandMessage format
    .map { tcpMessage in .commandAction(CommandMessage(text: tcpMessage.text, color: lineColor(tcpMessage.text), timeInterval: tcpMessage.timeInterval)) }
    .eraseToEffect()
    .cancellable(id: CommandSubscriptionId())
}

/// Assign each text line a color
/// - Parameter text:   the text line
/// - Returns:          a Color
private func lineColor(_ text: Substring) -> Color {
    if text.prefix(1) == "C" { return Color(.systemGreen) }                         // Commands
    if text.prefix(1) == "R" && text.contains("|0|") { return Color(.systemGray) }  // Replies no error
    if text.prefix(1) == "R" && !text.contains("|0|") { return Color(.systemRed) }  // Replies w/error
    if text.prefix(2) == "S0" { return Color(.systemOrange) }                       // S0

    return Color(.textColor)
}

/// Filter condition
/// - Parameter reply:   the text of a TcpCommand
/// - Returns:           a boolean
private func allowToPass(_ reply: Substring) -> Bool {
  if reply.first != "R" { return true }     // pass if not a Reply
  let parts = reply.components(separatedBy: "|")
  if parts.count < 3 { return true }        // pass if incomplete
  if parts[1] != kNoError { return true }   // pass if error of some type
  if parts[2] != "" { return true }         // pass if additional data present
  return false                              // otherwise, filter out (i.e. don't pass)
}
