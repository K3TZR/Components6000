//
//  WaterfallView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct WaterfallView: View {
  let store: Store<ApiState, ApiAction>
  let panadapterId: PanadapterId
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      
      ForEach(Array(viewStore.viewModel.waterfalls)) { waterfall in
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
      }
    }
  }
}
