//
//  GuiClients.swift
//  TestDiscoveryPackage/Discovery
//
//  Created by Douglas Adams on 11/6/21.
//

import Foundation

final public class GuiClients {
                                                        
  public var collection : [GuiClient] = []
//  {
//      get { _objectQ.sync { _collection } }
//      set { _objectQ.sync(flags: .barrier) { _collection = newValue }}}
  
  private static let _objectQ = DispatchQueue(label: "GuiClients.objectQ", attributes: [.concurrent])
  private static var _collection = [Packet]()
  
  /// Add a client to the collection
  /// - Parameter packet: a Packet
  public func add(_ client: GuiClient) {
    collection.append(client)
  }
  
  /// Remove a client from the collection
  /// - Parameter packet: a Packet
  public func remove(_ client: GuiClient) {
    collection.removeAll( where: {$0 == client} )
  }

  /// Update a client in the collection
  /// - Parameter packet: a Packet
  func update(_ client: GuiClient) {
    if let i = collection.firstIndex(of: client) {
      collection[i] = client
    }
  }
}
