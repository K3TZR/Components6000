//
//  ClientCore.swift
//  Components6000/ClientStatus
//
//  Created by Douglas Adams on 1/19/22.
//

import Foundation
import ComposableArchitecture

import Shared

public struct ClientState: Equatable {

  public init(pickerSelection: PickerSelection) {
    self.pickerSelection = pickerSelection
  }
  var pickerSelection: PickerSelection
}

public enum ClientAction: Equatable {
  // UI controls
  case cancelButton
  case connect(PickerSelection, Handle?)
}

public struct ClientEnvironment {
  public init() {}
}

public let clientReducer = Reducer<ClientState, ClientAction, ClientEnvironment>
  { state, action, environment in
      return .none
  }
