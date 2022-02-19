//
//  RemoteView.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 2/17/22.
//

import SwiftUI
import ComposableArchitecture

public struct RemoteView: View {
  let store: Store<RemoteState, RemoteAction>
  
  public init(store: Store<RemoteState, RemoteAction>) {
    self.store = store
  }
    public var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct RemoteView_Previews: PreviewProvider {
  static var previews: some View {
    RemoteView(store: Store(
      initialState: RemoteState(),
      reducer: remoteReducer,
      environment: RemoteEnvironment())
    )
  }
}
