//
//  InterlockView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct InterlockView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    HStack(spacing: 20) {
      Text("INTERLOCK -> ").frame(width: 140, alignment: .leading)
      Text("INTERLOCK NOT IMPLEMENTED")
    }
  }
}
