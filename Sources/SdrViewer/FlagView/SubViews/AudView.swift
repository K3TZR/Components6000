//
//  AudView.swift
//  
//
//  Created by Douglas Adams on 4/27/22.
//

import SwiftUI

struct AudView: View {
  
  @State var audioGain: CGFloat = 0.40
  @State var audioPan: CGFloat = 0.50
  @State var agcThreshold: CGFloat = 0.75

  @State var volume = 50.0
  @State var pan = 50.0
  @State var agcLevel = 50.0
  @State var selection = "off"
  @State var mute = false
  
  @State var choices = [
    "off",
    "slow",
    "med",
    "fast"
  ]
  
  var body: some View {
    VStack(spacing: 1) {
      HStack {
        VStack(spacing: 12) {
          Image(systemName: mute ? "speaker.slash": "speaker").font(.system(size: 20))
            .onTapGesture {}
          Text("L")
        }.font(.system(size: 12))
        
        VStack(spacing: -5)  {
          Slider(value: $audioGain, in: 0...100)
          Slider(value: $audioPan, in: 0...100)
          
        }
        VStack(spacing: 12) {
          Text(String(format: "%2.0f",audioGain)).frame(width: 30)
          Text("R")
        }.font(.system(size: 12))
      }
      
      HStack {
        Picker("", selection: $selection) {
          ForEach(choices, id: \.self) {
            Text($0)
          }
        }.frame(width: 100)
        Slider(value: $agcThreshold, in: 0...100)
        Text(String(format: "%2.0f",agcThreshold)).frame(width: 30)
      }.font(.system(size: 12))
    }
    .padding(.horizontal)
    .frame(height: 80)
  }
}

struct AudView_Previews: PreviewProvider {
    static var previews: some View {
      AudView()
        .frame(width: 275, height: 80)
    }
}
