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
        TextField("", text: viewStore.binding(\.$name)).frame(width: 250, alignment: .leading)
        Group {
          Toggle("", isOn: viewStore.binding(\.$physicalState)).disabled(true)
          Toggle("", isOn: viewStore.binding(\.$transientState)).disabled(true)
          Toggle("", isOn: viewStore.binding(\.$currentState)).disabled(viewStore.locked)
          Toggle("", isOn: viewStore.binding(\.$critical))
          Toggle("", isOn: viewStore.binding(\.$locked)).disabled(true)
        }
        .frame(width: 100, alignment: .center)
        TextField("", text: viewStore.binding(\.$cycleDelay))
          .frame(width: 100)
      }
      .font(.title2)
    }
  }
}
