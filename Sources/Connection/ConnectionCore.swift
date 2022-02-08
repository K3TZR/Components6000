//
//  ConnectionCore.swift
//  
//
//  Created by Douglas Adams on 1/19/22.
//

import Foundation
import ComposableArchitecture

import Shared

public struct ConnectionState: Equatable {

  public init(pickerSelection: PickerSelection) {
    self.pickerSelection = pickerSelection
  }
  var pickerSelection: PickerSelection
}

public enum ConnectionAction: Equatable {
  // UI controls
  case cancelButton
  case connect(PickerSelection, Handle?)
}

public struct ConnectionEnvironment {
  public init() {}
}

public let connectionReducer = Reducer<ConnectionState, ConnectionAction, ConnectionEnvironment>
  { state, action, environment in

    switch action {
    case .connect(let selection, let disconnectHandle):
      return .none

    case .cancelButton:
      // handled downstream
      return .none
    }
  }
