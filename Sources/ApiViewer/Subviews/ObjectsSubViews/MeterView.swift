//
//  MeterView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct MeterView: View {
  let store: Store<ApiState, ApiAction>
  let sliceId: ObjectId?
  
  func valueColor(_ value: Float, _ low: Float, _ high: Float) -> Color {
    if value > high { return .red }
    if value < low { return .yellow }
    return .green
  }
  
  func show(_ meter: Meter) -> Bool {
    sliceId == nil && meter.source != "slc" || sliceId != nil && meter.source == "slc" && UInt16(meter.group) == sliceId
  }

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let meters = Array(viewStore.radio!.meters.values).sorted {$0.id < $1.id}
        
        VStack(alignment: .leading) {
          ForEach(meters, id: \.id) { meter in
            HStack(spacing: 20) {
              if show(meter) {
                Text("Meter").frame(width: 50, alignment: .leading).padding(.leading, sliceId == nil ? 20 : 120)
                Text(String(format: "% 3d", meter.id)).frame(width: 50, alignment: .leading)
                Text(meter.group).frame(width: 50, alignment: .leading)
                Text(meter.name).frame(width: 120, alignment: .leading)
                Text(String(format: "%-4.2f", meter.low)).frame(width: 100, alignment: .trailing)
                Text(String(format: "%-4.2f", meter.value))
                  .foregroundColor(valueColor(meter.value, meter.low, meter.high))
                  .frame(width: 100, alignment: .trailing)
                Text(String(format: "%-4.2f", meter.high)).frame(width: 100, alignment: .trailing)
                Text(meter.units).frame(width: 50, alignment: .leading)
                Text(String(format: "%02d", meter.fps) + " fps").frame(width: 75, alignment: .leading)
                Text(meter.desc)
              }
            }
          }.foregroundColor(.secondary)
        }
      }
    }
  }
}

//struct MeterDetailView: View {
//  let store: Store<ApiState, ApiAction>
//  let sliceId: ObjectId?
//  
//  func valueColor(_ value: Float, _ low: Float, _ high: Float) -> Color {
//    if value > high { return .red }
//    if value < low { return .yellow }
//    return .green
//  }
//  
//  func show(_ meter: Meter) -> Bool {
//    sliceId == nil && meter.source != "slc" || sliceId != nil && meter.source == "slc" && UInt16(meter.group) == sliceId
//  }
//  
//  var body: some View {
//    HStack(spacing: 20) {
//      if show(meter) {
//        Text("Meter").frame(width: 50, alignment: .leading).padding(.leading, sliceId == nil ? 20 : 120)
//        Text(String(format: "% 3d", meter.id)).frame(width: 50, alignment: .leading)
//        Text(meter.group).frame(width: 50, alignment: .leading)
//        Text(meter.name).frame(width: 120, alignment: .leading)
//        Text(String(format: "%-4.2f", meter.low)).frame(width: 100, alignment: .trailing)
//        Text(String(format: "%-4.2f", meter.value))
//          .foregroundColor(valueColor(meter.value, meter.low, meter.high))
//          .frame(width: 100, alignment: .trailing)
//        Text(String(format: "%-4.2f", meter.high)).frame(width: 100, alignment: .trailing)
//        Text(meter.units).frame(width: 50, alignment: .leading)
//        Text(String(format: "%02d", meter.fps) + " fps").frame(width: 75, alignment: .leading)
//        Text(meter.desc)
//      }
//    }
//  }
//}
