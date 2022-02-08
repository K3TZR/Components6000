//
//  RadioReplyHandlers.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 1/21/22.
//

import Foundation

import Shared

extension Radio {
  // ----------------------------------------------------------------------------
  // MARK: - ReplyHandlers

  /// Add a Reply Handler for a specific Sequence/Command
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - sequenceId:     sequence number of the Command
  ///   - replyTuple:     a Reply Tuple
  func addReplyHandler(_ seqNumber: UInt, replyTuple: ReplyTuple) {
      // add the handler
      replyHandlers[seqNumber] = replyTuple
  }

  /// Process the Reply to a command, reply format: <value>,<value>,...<value>
  /// - Parameters:
  ///   - command:        the original command
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    guard responseValue == kNoError else {

      // ignore non-zero reply from "client program" command
      if !command.hasPrefix("client program ") {
        // Anything other than 0 is an error, log it and ignore the Reply
        let errorLevel = flexErrorLevel(errorCode: responseValue)
        _log("Radio, reply to c\(sequenceNumber), \(command): non-zero reply \(responseValue), \(flexErrorString(errorCode: responseValue))", errorLevel, #function, #file, #line)
      }
      return
    }

    // which command?
    switch command {

    case "client gui":    bindGuiClient(reply, callback: defaultReplyHandler)
    case "slice list":    sliceList = reply.valuesArray().compactMap {$0.objectId}
    case "ant list":      antennaList = reply.valuesArray( delimiter: "," )
    case "info":          parseInfoReply( (reply.replacingOccurrences(of: "\"", with: "")).keyValuesArray(delimiter: ",") )
    case "mic list":      micList = reply.valuesArray(  delimiter: "," )
    case "radio uptime":  uptime = Int(reply) ?? 0
    case "version":       parseVersionReply( reply.keyValuesArray(delimiter: "#") )
    default:              break
    }
  }
  
  /// Reply handler for the "wan validate" command
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contained in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  func wanValidateReplyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    // return status
    updateState(to: .wanHandleValidated(success: responseValue == Shared.kNoError))
  }
}
