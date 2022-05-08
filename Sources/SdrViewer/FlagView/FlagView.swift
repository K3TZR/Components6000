//
//  FlagView.swift
//  Components/SdrViewer/SubViews/SideViews
//
//  Created by Douglas Adams on 4/3/21.
//  Copyright © 2020-2021 Douglas Adams. All rights reserved.
//

import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - Main view

struct FlagView: View {

  @State var selectedTab = 0

  var body: some View {    
    VStack(alignment: .leading) {
      FlagTopView( )
      FlagBottomView(selectedTab: $selectedTab)
      Divider().background(.blue)
    }
    .frame(width: 260)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Major views

struct FlagTopView: View {
  
  @State var rxAntennas = ["Ant1", "Ant2", ]
  @State var selectedRxAntenna = "Ant1"
  @State var txAntennas = ["Ant1", "Ant2", ]
  @State var selectedTxAntenna = "Ant1"
  @State var frequency = 14_200_000
  
  var body: some View {
    VStack {
      HStack {
        Button(action: {}) {Text("X").frame(width: 8)}
        Picker("", selection: $selectedRxAntenna) {
          ForEach(rxAntennas, id: \.self) {
            Text($0)
          }
        }.frame(width: 75)
        Picker("", selection: $selectedTxAntenna) {
          ForEach(txAntennas, id: \.self) {
            Text($0)
          }
        }.frame(width: 75)
        
      }
      TextField(
        "Frequency",
        value: $frequency,
        formatter: NumberFormatter()
      )
      .multilineTextAlignment(.trailing)
      .frame(width: 100)
    }
    .frame(height: 100)
  }
}

struct FlagBottomView: View {
  @Binding var selectedTab: Int
  
  var body: some View {
    TabView(selection: $selectedTab) {
      AudView()
        .tabItem {Text("AUD")}
        .tag(0)
      DspView()
        .tabItem {Text("DSP")}
        .tag(1)
      ModeView()
        .tabItem {Text("MODE")}
        .tag(2)
      XritView()
        .tabItem {Text("XRIT")}
        .tag(3)
      DaxView()
        .tabItem {Text("DAX")}
        .tag(4)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct FlagView_Previews: PreviewProvider {
  static var previews: some View {
    FlagView(selectedTab: 0)
      .frame(width: 260, height: 220)
    FlagView(selectedTab: 1)
      .frame(width: 260, height: 230)
    FlagView(selectedTab: 2)
      .frame(width: 260, height: 220)
    FlagView(selectedTab: 3)
      .frame(width: 260, height: 220)
    FlagView(selectedTab: 4)
      .frame(width: 260, height: 220)
  }
}
