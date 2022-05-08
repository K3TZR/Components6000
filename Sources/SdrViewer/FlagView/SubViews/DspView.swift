//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 4/27/22.
//

import SwiftUI

struct DspView: View {
  
  @State var level1 = 50.0
  @State var level2 = 50.0
  @State var level3 = 50.0
  @State var level4 = 50.0
  
  var body: some View {
    HStack(spacing: 20) {
      VStack(spacing: 5) {
        Button(action: {}) {Text("WNB").frame(width: 35)}
        Button(action: {}) {Text("NB").frame(width: 35)}
        Button(action: {}) {Text("NR").frame(width: 35)}
        Button(action: {}) {Text("ANF").frame(width: 35)}
      }
      
      VStack(spacing: -5) {
        Slider(value: $level1, in: 0...100)
        Slider(value: $level2, in: 0...100)
        Slider(value: $level3, in: 0...100)
        Slider(value: $level4, in: 0...100)
      }
      
      VStack(spacing: 12) {
        Text(String(format: "%2.0f",level1)).frame(width: 30)
        Text(String(format: "%2.0f",level2)).frame(width: 30)
        Text(String(format: "%2.0f",level3)).frame(width: 30)
        Text(String(format: "%2.0f",level4)).frame(width: 30)
      }
    }
    .padding(.horizontal)
    .frame(height: 100)
  }
}

struct DspView_Previews: PreviewProvider {
    static var previews: some View {
      DspView()
        .frame(width: 275, height: 100)
    }
}
