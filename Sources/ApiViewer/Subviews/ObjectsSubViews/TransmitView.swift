//
//  TransmitView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

import Radio

struct TransmitView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let transmit = Objects.sharedInstance.transmit!
        let width: CGFloat = 80
        
        VStack {
          HStack(spacing: 20) {
            Text("Transmit").frame(width: 100, alignment: .trailing)
            Text("RF Power \(transmit.rfPower)")
            Text("Tune Power \(transmit.tunePower)")
            Text("Frequency \(transmit.frequency)")
            Text("Mon Level \(transmit.txMonitorGainSb)")
            Text("Comp Level \(transmit.companderLevel)")
            Text("Mic \(transmit.micSelection)")
            Text("Mic Level \(transmit.micLevel)")
            Text("Vox Delay \(transmit.voxDelay)")
            Text("Vox Level \(transmit.voxLevel)")
          }
          HStack(spacing: 60) {
            Text("Proc \(transmit.speechProcessorEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.speechProcessorEnabled ? .green : .red)
            Text("Mon \(transmit.txMonitorEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.txMonitorEnabled ? .green : .red)
            Text("Acc \(transmit.micAccEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.micAccEnabled ? .green : .red)
            Text("Comp \(transmit.companderEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.companderEnabled ? .green : .red)
            Text("Dax \(transmit.daxEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.daxEnabled ? .green : .red)
            Text("Vox \(transmit.voxEnabled ? "ON" : "OFF")")
              .foregroundColor(transmit.voxEnabled ? .green : .red)
          }
          .frame(width: width, alignment: .center)
        }
      }
    }
  }
}
