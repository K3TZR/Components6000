//
//  GpsView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct GpsView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    //        let gps = radio.gps!
    
    HStack(spacing: 20) {
      Text("GPS -> ").frame(width: 140, alignment: .leading)
      Text("GPS NOT IMPLEMENTED")
    }
  }
}
