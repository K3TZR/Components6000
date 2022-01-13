//
//  ObjectsEffects.swift
//  Components6000/ApiObjects
//
//  Created by Douglas Adams on 1/12/22.
//

import Foundation
import ComposableArchitecture

//public func listenForObjects(_ command: Command, parseQ: DispatchQueue) -> Effect<ObjectsAction, Never> {
//
//  return
//    command.commandPublisher
//      .receive(on: parseQ)
//      .map { text in .objectsAction(text) }
//      .eraseToEffect()
//      .cancellable(id: ObjectsSubscriptionId())
//}
