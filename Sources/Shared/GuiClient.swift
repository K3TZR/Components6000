//
//  GuiClient.swift
//  TestDiscoveryPackage/Discovery
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import Combine

public struct GuiClient: Equatable, Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var id: Handle { clientHandle }

  public var clientId: GuiClientId?
  public var clientHandle: Handle = 0
  public var host = ""
  public var ip = ""
  public var isLocalPtt = false
  public var isThisClient = false
  public var program = ""
  public var station = ""
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(clientHandle: Handle, station: String, program: String,
              clientId: GuiClientId? = nil, host: String = "", ip: String = "",
              isLocalPtt: Bool = false, isThisClient: Bool = false) {
    
    self.clientHandle = clientHandle
    self.station = station
    self.program = program
    self.clientId = clientId
    self.host = host
    self.ip = ip
    self.isLocalPtt = isLocalPtt
    self.isThisClient = isThisClient
  }

  public static func == (lhs: GuiClient, rhs: GuiClient) -> Bool {
    lhs.clientHandle == rhs.clientHandle
  }  
}
