//
//  PhoneView.swift
//  
//
//  Created by Douglas Adams on 4/29/22.
//

import SwiftUI
import LevelIndicator


struct PhoneView: View {

  @State var delay: CGFloat = 0.8
  @State var rfPower: CGFloat = 1.1
  @State var swr: CGFloat = 2.5
  @State var tunePower: CGFloat = 0.0
  @State var selectedTxProfile = "Profile 1"
  @State var txProfiles = ["Profile 1", "Profile 2", "Profile 3"]
  @State var atuState = "ByPass"

  @State var level: CGFloat = 0.95

  var body: some View {
    VStack(alignment: .leading, spacing: 10)  {
      LevelIndicatorView(level: rfPower, style: rfPowerStyle)
      LevelIndicatorView(level: swr, style: swrStyle)
      
      HStack {
        Text("RF Power").frame(width: 80, alignment: .leading)
        Text("\(String(format: "%.0f", rfPower))")
        Spacer()
        Slider(value: $rfPower, in: -1...1).frame(width: 120)
      }
      HStack() {
        Text("Tune Power").frame(width: 80, alignment: .leading)
        Text("\(String(format: "%.0f", tunePower))")
        Spacer()
        Slider(value: $tunePower, in: -1...1).frame(width: 120)
      }
      
      HStack(spacing: 10) {
        Picker("", selection: $selectedTxProfile) {
          ForEach(txProfiles, id: \.self) {
            Text($0)
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(width: 80, alignment: .leading)
        Button(action: {}) { Text("Save").frame(width: 30) }
        TextField("", text: $atuState).frame(width: 100)
      }

      HStack(spacing: 20) {
        Button(action: {}) { Text("Tune") }
        Button(action: {}) { Text("MOX") }
        Button(action: {}) { Text("ATU") }
        Button(action: {}) { Text("Mem") }
      }
      
      Divider().background(.blue)
    }
    .padding(.horizontal, 10)
    .frame(height: 230)
  }
}

struct PhoneView_Previews: PreviewProvider {
  static var previews: some View {
    PhoneView()
      .frame(width: 260, height: 230)
  }
}
