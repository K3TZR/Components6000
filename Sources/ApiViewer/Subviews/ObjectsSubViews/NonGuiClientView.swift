//
//  NonGuiClientView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/25/22.
//

import SwiftUI
import ComposableArchitecture

struct NonGuiClientView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      if viewStore.radio != nil {
        VStack(alignment: .leading) {
          Divider().foregroundColor(Color(.systemRed))
          HStack(spacing: 20) {
            Text("NONGUI CLIENT -> ").frame(width: 140, alignment: .leading)
            Text(viewStore.radio!.station).frame(width: 120, alignment: .leading)
          }
          if viewStore.objectsFilterBy == .streams { StreamView(store: store) }
          if viewStore.objectsFilterBy == .transmit { TransmitView(store: store) }
        }
      }
    }
  }
}
