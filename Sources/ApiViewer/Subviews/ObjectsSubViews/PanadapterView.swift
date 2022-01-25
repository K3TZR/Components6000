//
//  PanadapterView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Shared

struct PanadapterView: View {
  let store: Store<ApiState, ApiAction>
  let handle: Handle
  let showMeters: Bool
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        
        let panadapters = Array(viewStore.radio!.panadapters.values)
        
        ForEach(panadapters) { panadapter in
          if panadapter.clientHandle == handle {
            HStack(spacing: 20) {
              Text("Panadapter").frame(width: 100, alignment: .trailing)
              Text(panadapter.id.hex)
              Text("Center \(panadapter.center)")
              Text("Bandwidth \(panadapter.bandwidth)")
            }
            WaterfallView(store: store, panadapterId: panadapter.id)
            SliceView(store: store, panadapterId: panadapter.id, showMeters: showMeters)
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
