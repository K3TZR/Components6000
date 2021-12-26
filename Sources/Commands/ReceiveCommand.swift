//
//  ReceiveCommand.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import LogProxy
import Shared

extension Command {
  
//  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//    // TODO: REMOVE THIS LOG
//    _log(LogEntry("-----> Command: socket did receive -> \(String(data: data, encoding: .ascii) ?? "")", .debug, #function, #file, #line))
//
//    // publish the received data
//    if let text = String(data: data, encoding: .ascii) {
//      receivedDataPublisher.send(text)
//    }
//    // trigger the next read
//    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
//  }
//  
//  public func socketDidSecure(_ sock: GCDAsyncSocket) {
//    // TLS connection complete
//    _log(LogEntry("Command: TLS socket did secure", .debug, #function, #file, #line))
//    statusPublisher.send(
//      TcpStatus(isConnected: true,
//                host: sock.connectedHost ?? "",
//                port: sock.connectedPort,
//                error: nil)
//    )
//  }
//  
//  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//    // there are no validations for the radio connection
//    _log(LogEntry("Command: TLS socket did receive trust", .debug, #function, #file, #line))
//    completionHandler(true)
//  }
}
