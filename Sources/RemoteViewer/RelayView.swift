//
//  RelayView.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 3/11/22.
//

import ComposableArchitecture
import SwiftUI

public struct RelayView: View {
  let store: Store<Relay, RelayAction>

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack {
        Text(viewStore.name == "" ? "-- none --" : viewStore.name)
          .frame(width: 250, alignment: .leading)
        HStack {
          Text("\(viewStore.physicalState ? "ON" : " ")").frame(width: 100, alignment: .center)
          Text("\(viewStore.transientState ? "ON" : " ")").frame(width: 100, alignment: .center)
          Text("\(viewStore.currentState ? "ON" : " ")").frame(width: 100, alignment: .center)
          Text("\(viewStore.critical ? "T" : " ")").frame(width: 100, alignment: .center)
          Text("\(viewStore.locked ? "T" : " ")").frame(width: 100, alignment: .center)
        }
        Text("\(viewStore.cycleDelayString)").frame(width: 100, alignment: .trailing)
      }
      .font(.title2)
    }
  }
}
