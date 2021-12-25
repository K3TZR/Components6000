//
//  ReceiveCommand.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Shared

extension Command {
  
  func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // publish the received data
    if let text = String(data: data, encoding: .ascii) {
      receivedDataPublisher.send(text)
    }
    // trigger the next read
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    // TLS connection complete
    statusPublisher.send(
      TcpStatus(isConnected: true,
                host: sock.connectedHost ?? "",
                port: sock.connectedPort,
                error: nil)
    )
  }
  
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // there are no validations for the radio connection
    completionHandler(true)
  }
}
