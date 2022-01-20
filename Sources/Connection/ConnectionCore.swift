//
//  ConnectionCore.swift
//  
//
//  Created by Douglas Adams on 1/19/22.
//

import Foundation
import ComposableArchitecture

import Shared
import Picker

public struct ConnectionState: Equatable {

  public init(pickerSelection: PickerSelection) {
    self.pickerSelection = pickerSelection
  }
  var pickerSelection: PickerSelection
}

public enum ConnectionAction: Equatable {
  // UI controls
  case cancelButton
  case simpleConnect
//  case disconnectThenConnect(PickerSelection, PickerSelection)
  case disconnectThenConnect
}

public struct ConnectionEnvironment {
}

let connectionReducer = Reducer<ConnectionState, ConnectionAction, ConnectionEnvironment>
  { state, action, environment in

    switch action {
    case .disconnectThenConnect:
      print("-----> DisconnectThenConnect")
      return .none

    case .simpleConnect:
      print("-----> simpleConnection")
      return .none

    case .cancelButton:
      print("-----> cancelButton")
      return .none
    }
  }
