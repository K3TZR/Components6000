//
//  Packets.swift
//  FlexComponents/Discovery
//
//  Created by Douglas Adams on 11/5/21.
//

import Foundation

final public class Packets {
                                                        
  public var collection: [Packet] = []
//  {
//      get { _objectQ.sync { _collection } }
//      set { _objectQ.sync(flags: .barrier) { _collection = newValue }}}
  
  private static let _objectQ = DispatchQueue(label: "Packets.objectQ", attributes: [.concurrent])
  private static var _collection = [Packet]()
  
  public init() {}
  
  /// Add a packet to the collection
  /// - Parameter packet: a Packet
  public func add(_ packet: Packet) {
    collection.append(packet)
  }

  /// Update a packet in the collection
  /// - Parameter packet: a Packet
  public func update(_ packet: Packet) {
    if let i = collection.firstIndex(of: packet) {
      collection[i] = packet
    }
  }

  /// Remove a packet from the collection
  /// - Parameter packet: a Packet
  public func remove(_ packet: Packet) {
    collection.removeAll( where: {$0 == packet} )
  }

  /// Remove a packet from the collection
  /// - Parameter condition:  a closure defining the condition for removal
  public func remove(condition: (Packet) -> Bool) -> [Packet] {
    var deleteList = [Packet]()
    
    for packet in collection where condition(packet) {
      deleteList.append(packet)
    }
    for packet in deleteList {
      remove(packet)
    }
    return deleteList
  }
  
  /// Is the packet known (i.e. in the collection)
  /// - Parameter packet: the incoming packet
  /// - Returns: the index, if any, of the matching packet
  public func isKnownPacket(_ packet: Packet) -> Int? {
    if let index = collection.firstIndex(where: { $0 == packet }) {
      // update the lastSeen property
      collection[index].lastSeen = Date()
      return index
    }
    return nil
  }
}
