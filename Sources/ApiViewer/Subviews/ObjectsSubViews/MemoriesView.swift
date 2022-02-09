//
//  MemoriesView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct MemoriesView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    
    HStack(spacing: 20) {
      Text("MEMORIES -> ").frame(width: 140, alignment: .leading)
      Text("MEMORIES NOT IMPLEMENTED")
    }
  }
}
