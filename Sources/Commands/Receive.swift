//
//  Receive.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import CocoaAsyncSocket

extension Command {

  /// Receive a Command (text) from the connected Radio, publishes the received text
  /// - Parameters:
  ///   - sock:       the connected socket
  ///   - data:       the dat received
  ///   - tag:        the tag on the received data
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // publish the received data, remove the EOL
    if let text = String(data: data, encoding: .ascii)?.dropLast() {
      commandPublisher.send(text)
    }
    // trigger the next read
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }

}
