//
//  CwView.swift
//  
//
//  Created by Douglas Adams on 4/28/22.
//

import SwiftUI

//import LevelIndicator

struct CwView: View {

  @State var delay: CGFloat = 0.8
  @State var speed: CGFloat = 0.7
  @State var sideTone: CGFloat = 0.3
  @State var pan: CGFloat = 0.0
  @State var pitch = "1,000"

  @State var level: CGFloat = 0.5
  
  var body: some View {

    VStack(alignment: .leading, spacing: 0)  {
      
//      LevelIndicatorView(level: $level)
      
      HStack(spacing: 15) {
        Text("Delay").frame(width: 60, alignment: .leading)
        Text("\(String(format: "%.0f", delay))")
        Slider(value: $delay, in: -1...1).frame(width: 120)
      }
      HStack(spacing: 15) {
        Text("Speed").frame(width: 60, alignment: .leading)
        Text("\(String(format: "%.0f", speed))")
        Slider(value: $speed, in: -1...1).frame(width: 120)
      }
      HStack(spacing: 25) {
        Button(action: {}) { Text("Sidetone").frame(width: 55) }
        Slider(value: $sideTone, in: -1...1).frame(width: 120)
      }
      HStack(spacing: 5) {
        Text("Pan").frame(width: 75, alignment: .leading)
        Text("L").frame(width: 10)
        Slider(value: $pan, in: -1...1).frame(width: 120)
        Text("R").frame(width: 10)
      }
      HStack(spacing: 5) {
        Button(action: {}) { Text("Breakin").frame(width: 50) }
        Button(action: {}) { Text("Iambic").frame(width: 50) }
        Text("Pitch")
        TextField("", text: $pitch)
      }
    }
    .padding(.horizontal, 10)
    .frame(height: 180)
  }
}

struct CwView_Previews: PreviewProvider {
    static var previews: some View {
      CwView()
        .padding(.horizontal, 10)
        .frame(width: 260, height: 180)
    }
}
