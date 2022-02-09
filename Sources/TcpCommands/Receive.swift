//
//  Receive.swift
//  Components6000/TcpCommands
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import CocoaAsyncSocket

extension Tcp {

  /// Receive a Command (text) from the connected Radio, publishes the received text
  /// - Parameters:
  ///   - sock:       the connected socket
  ///   - data:       the dat received
  ///   - tag:        the tag on the received data
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // publish the received data, remove the EOL
    if let text = String(data: data, encoding: .ascii)?.dropLast() {
      receivedPublisher.send(TcpMessage(timeInterval: Date().timeIntervalSince( _startTime!), direction: .received, text: String(text)))
    }
    // trigger the next read
    readNext()
  }

}
