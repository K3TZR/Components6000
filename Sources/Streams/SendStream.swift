//
//  SendStream.swift
//  Components6000/Streams
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket

extension Stream {

  /// Send message (as Data) to the Radio using UDP on the current ip & port
  /// - Parameters:
  ///   - data:               a Data
  func sendData(_ data: Data) {
    _socket.send(data, toHost: _sendIp, port: _sendPort, withTimeout: -1, tag: 0)
  }
}
