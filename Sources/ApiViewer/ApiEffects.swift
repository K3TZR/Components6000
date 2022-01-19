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

public func listenForCommands(_ command: TcpCommand) -> Effect<ApiAction, Never> {

  command.commandPublisher
    .filter { allowToPass($0.text) }
    .receive(on: DispatchQueue.main)
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

private func allowToPass(_ reply: Substring) -> Bool {

  // is it a Reply message
  if reply.first != "R" { return true }
  // YES, only pass it if it indicates an error or shows additional data
  let parts = reply.components(separatedBy: "|")
  if parts[1] != kNoError {return true}
  if parts[2] != "" { return true }
  return false
}
