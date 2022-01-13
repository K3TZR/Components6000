//
//  ObjectsCore.swift
//  Components6000/ApiObjects
//
//  Created by Douglas Adams on 1/12/22.
//

import Foundation
import Combine

import Commands
import Shared

public final class ObjectsState: Equatable {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public static func == (lhs: ObjectsState, rhs: ObjectsState) -> Bool { lhs === rhs }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let _parseQ = DispatchQueue(label: "ObjectsCore.parseQ", qos: .userInteractive)
  private var _command: Command!
  private var _cancellable: AnyCancellable?
  private var _connectionHandle: Handle?
  private var _hardwareVersion: String?

  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ command: Command) {
    _command = command
    _cancellable = command.commandPublisher
      .receive(on: _parseQ)
      .sink { [weak self] msg in
        self?.receivedMessage(msg)
      }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Parse  Command messages from the Radio
  ///
  /// - Parameter msg:        the Message String
  private func receivedMessage(_ msg: Substring) {
    // get all except the first character
    let suffix = String(msg.dropFirst())

    print("-----> Api: \(msg[msg.startIndex]) received, \(suffix)")
    // switch on the first character (message type)
    switch msg[msg.startIndex] {

    case "H", "h":  _connectionHandle = suffix.handle
    case "M", "m":  parseMessage( msg.dropFirst() )
    case "R", "r":  parseReply( msg.dropFirst() )
    case "S", "s":  parseStatus( msg.dropFirst() )
    case "V", "v":  _hardwareVersion = suffix
    default:        print("-----> Radio, unexpected message: \(msg)")
    }
  }

  /// Parse a Message.
  ///
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseMessage(_ msg: Substring) {
    // separate it into its components
    let components = msg.components(separatedBy: "|")

    // ignore incorrectly formatted messages
    if components.count < 2 {
      print("-----> Radio, incomplete message: c\(msg)")
      return
    }
    let msgText = components[1]

    // log it
    print("-----> Radio, message: \(msgText)", flexErrorLevel(errorCode: components[0]))

    // FIXME: Take action on some/all errors?
  }

  private func parseReply(_ msg: Substring) {

  }

  private func parseStatus(_ msg: Substring) {

  }
}
