//
//  VitaParser.swift
//  Components6000/Discovery/Lan
//
//  Created by Douglas Adams on 12/10/21.
//

import Foundation
import Shared

extension LanListener {
  
  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  func parseVita(_ vita: Vita) -> Packet? {
    // is this a Discovery packet?
    if vita.classIdPresent && vita.classCode == .discovery {
      // Payload is a series of strings of the form <key=value> separated by ' ' (space)
      var payloadData = NSString(bytes: vita.payloadData, length: vita.payloadSize, encoding: String.Encoding.ascii.rawValue)! as String
      
      // eliminate any Nulls at the end of the payload
      payloadData = payloadData.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
      
      return _discovery?.populatePacket( payloadData.keyValuesArray() )
    }
    return nil
  }
}

