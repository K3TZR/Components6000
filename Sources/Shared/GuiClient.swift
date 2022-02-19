//
//  GuiClient.swift
//  Components6000/Discovery
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import Combine

public enum ActionType: String {
  case added
  case deleted
  case updated
}
public struct ClientUpdate: Equatable {
  
  public init(_ action: ActionType, client: GuiClient, source: PacketSource) {
    self.action = action
    self.client = client
    self.source = source
  }
  public var action: ActionType
  public var client: GuiClient
  public var source: PacketSource
}

public struct GuiClient: Equatable, Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  public var id: Handle { handle }
  
  public var clientId: GuiClientId?
  public var handle: Handle = 0
  public var host = ""
  public var ip = ""
  public var isLocalPtt = false
  public var isThisClient = false
  public var program = ""
  public var station = ""
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(handle: Handle, station: String, program: String,
              clientId: GuiClientId? = nil, host: String = "", ip: String = "",
              isLocalPtt: Bool = false, isThisClient: Bool = false) {
    
    self.handle = handle
    self.clientId = clientId
    self.host = host
    self.ip = ip
    self.isLocalPtt = isLocalPtt
    self.isThisClient = isThisClient
    self.program = program
    self.station = station
  }
  
  public static func == (lhs: GuiClient, rhs: GuiClient) -> Bool {
    lhs.handle == rhs.handle
  }
}
