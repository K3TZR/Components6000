//
//  RemoteCore.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 1/19/22.
//

import Foundation
import ComposableArchitecture

public struct RemoteState: Equatable {
  public init() {}
}

public enum RemoteAction: Equatable {
  case cancel
}

public struct RemoteEnvironment {
  public init() {}
}

public let remoteReducer = Reducer<RemoteState, RemoteAction, RemoteEnvironment>
  { state, action, environment in
      return .none
  }
