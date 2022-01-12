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

import Commands
import Shared

public func listenForCommands(_ command: Command) -> Effect<ApiAction, Never> {

  return
    command.commandPublisher
      .receive(on: DispatchQueue.main)
      .map { text in .commandAction(CommandMessage(text: text, color: lineColor(text))) }
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
