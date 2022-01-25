//
//  WaterfallView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Shared

struct WaterfallView: View {
  let store: Store<ApiState, ApiAction>
  let panadapterId: PanadapterStreamId
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        
        let waterfalls = Array(viewStore.radio!.waterfalls.values)
        
        ForEach(waterfalls) { waterfall in
          if waterfall.panadapterId == panadapterId {
            HStack(spacing: 20) {
              Text("Waterfall").frame(width: 100, alignment: .trailing)
              Text(waterfall.id.hex)
              Text("AutoBlack \(waterfall.autoBlackEnabled ? "Y" : "N")")
              Text("ColorGain \(waterfall.colorGain)")
              Text("BlackLevel \(waterfall.blackLevel)")
              Text("Duration \(waterfall.lineDuration)")
            }
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
