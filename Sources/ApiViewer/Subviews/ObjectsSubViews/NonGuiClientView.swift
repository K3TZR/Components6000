//
//  NonGuiClientView.swift
//  
//
//  Created by Douglas Adams on 1/25/22.
//

import SwiftUI
import ComposableArchitecture

struct NonGuiClientView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        VStack(alignment: .leading) {
          Divider().foregroundColor(Color(.systemRed))
          HStack(spacing: 20) {
            Text("NONGUI CLIENT -> ").frame(width: 140, alignment: .leading)
            Text(viewStore.radio!.station).frame(width: 120, alignment: .leading)
//            Text("Handle \(viewStore.radio!.connectionHandle!.hex)")
          }
          if viewStore.objectsFilterBy == .streams { StreamView(store: store) }
          if viewStore.objectsFilterBy == .transmit { TransmitView(store: store) }
        }
      }
    }
  }
}
