//
//  ApiEffects.swift
//  
//
//  Created by Douglas Adams on 1/7/22.
//

import Foundation
import ComposableArchitecture
import Combine

import Commands
import Shared

public func listenForCommands(_ command: Command) -> Effect<ApiAction, Never> {

  return
    command.commandPublisher
      .receive(on: DispatchQueue.main)
      .map { text in .commandAction(CommandMessage(text: text)) }
      .eraseToEffect()
      .cancellable(id: CommandSubscriptionId())
}
