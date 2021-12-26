//
//  SendCommand.swift
//  Components6000/Commands
//
//  Created by Douglas Adams on 12/22/21.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import Combine

import LogProxy
import Shared

extension Command {
  
//  /// Send a Command to the Radio (hardware)
//  /// - Parameters:
//  ///   - cmd:            a Command string
//  ///   - diagnostic:     whether to add "D" suffix
//  /// - Returns:          the Sequence Number of the Command
//  public func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
//    let assignedNumber = sequenceNumber
//    
//    _sendQ.sync {
//      // assemble the command
//      let command =  "C" + "\(diagnostic ? "D" : "")" + "\(self.sequenceNumber)|" + cmd + "\n"
//      
//      // send it, no timeout, tag = segNum
//      self._socket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: assignedNumber)
//      
//      // atomically increment the Sequence Number
//      $sequenceNumber.mutate { $0 += 1}
//
//      // TODO: REMOVE THIS LOG
//      _log(LogEntry("-----> Command: did send \(command)", .debug, #function, #file, #line))
//    }
//    // return the Sequence Number used by this send
//    return UInt(assignedNumber)
//  }
}
