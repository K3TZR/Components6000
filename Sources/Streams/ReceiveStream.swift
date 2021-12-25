//
//  ReceiveStream.swift
//  Components6000/Streams
//
//  Created by Douglas Adams on 12/24/21.
//

import Foundation
import CocoaAsyncSocket

import LogProxy
import Shared

extension Stream: GCDAsyncUdpSocketDelegate {
  // All execute on the receiveQ
  
  func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
    _processQ.async { [weak self] in
      
      if let vita = Vita.decode(from: data) {
        // TODO: Packet statistics - received, dropped
        
        // a VITA packet was received therefore registration was successful
        self?._isRegistered = true
        
        // TODO: publish?
        
        
      } else {
        self?._log(LogEntry("Stream: Unable to decode Vita packet", .warning, #function, #file, #line))
      }
    }
  }
}
