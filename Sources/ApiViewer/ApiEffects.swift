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
    .filter { ($0.prefix(1) == "R" && $0.contains("|0|")) == false }
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
