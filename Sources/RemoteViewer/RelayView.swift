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
        TextField("", text: viewStore.binding(\.$name), onCommit: { viewStore.send(.nameChanged) }).frame(width: 300)
        Group {
          
          Button(action: { viewStore.send(.toggleStatus) }, label: { Text("\(viewStore.status ? "ON" : "OFF")").frame(width: 40) })
            .foregroundColor(viewStore.locked ? .gray : viewStore.status ? .green : .red)
            .disabled(viewStore.locked)
          Text("\(viewStore.locked ? "YES" : "NO")").foregroundColor(viewStore.locked ? .yellow : .gray)
        }
        .frame(width: 100, alignment: .center)
      }
      .font(.title2)
    }
  }
}
