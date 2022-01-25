//
//  BandSettingsView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct BandSettingsView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    //        let bandSettings = radio.bandsettings!
    
    HStack(spacing: 20) {
      Text("BANDSETTINGS -> ").frame(width: 140, alignment: .leading)
      Text("BANDSETTINGS NOT IMPLEMENTED")
    }
  }
}
