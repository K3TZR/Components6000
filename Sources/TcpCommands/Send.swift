//
//  SendCommand.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import Shared

extension TcpCommand {
  /// Send a Command to the connected Radio
  /// - Parameters:
  ///   - cmd:            a Command string
  ///   - diagnostic:     whether to add "D" suffix
  /// - Returns:          the Sequence Number of the Command
  public func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
    let assignedNumber = sequenceNumber

    _sendQ.sync {
      // assemble the command
      let command =  "C" + "\(diagnostic ? "D" : "")" + "\(self.sequenceNumber)|" + cmd + "\n"

      // send it, no timeout, tag = segNum
      self._socket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: assignedNumber)

      sentPublisher.send(TcpMessage(timeInterval: Date().timeIntervalSince( _startTime!), text: String(command.dropLast())))

      // atomically increment the Sequence Number
      $sequenceNumber.mutate { $0 += 1}
    }
    // return the Sequence Number used by this send
    return UInt(assignedNumber)
  }
}
