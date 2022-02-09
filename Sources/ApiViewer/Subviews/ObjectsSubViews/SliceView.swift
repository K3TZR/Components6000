//
//  SliceView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct SliceView: View {
  let store: Store<ApiState, ApiAction>
  let panadapterId: PanadapterStreamId
  let showMeters: Bool
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        
        let slices = Array(Objects.sharedInstance.slices.values)

          ForEach(slices) { slice in
            if slice.panadapterId == panadapterId {
              HStack(spacing: 20) {
                Text("Slice").frame(width: 100, alignment: .trailing)
                Text(String(format: "% 3d", slice.id))
                Text("\(slice.frequency)")
                Text("\(slice.mode)")
                Text("FilterLow \(slice.filterLow)")
                Text("FilterHigh \(slice.filterHigh)")
                Text("Active \(slice.active ? "Y" : "N")")
                Text("Locked \(slice.locked ? "Y" : "N")")
                Text("DAX channel \(slice.daxChannel)")
                Text("DAX clients \(slice.daxClients)")
              }
              if showMeters { MeterView(store: store, sliceId: slice.id) }
            }
          }
        }
      }
    }
  }
