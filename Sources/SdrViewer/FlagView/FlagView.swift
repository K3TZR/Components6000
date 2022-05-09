//
//  FlagView.swift
//  Components/SdrViewer/SubViews/SideViews
//
//  Created by Douglas Adams on 4/3/21.
//  Copyright © 2020-2021 Douglas Adams. All rights reserved.
//

import SwiftUI

import LevelIndicator

// ----------------------------------------------------------------------------
// MARK: - Main view

struct FlagView: View {

  @State var selectedTab = 0

  var body: some View {    
    VStack(alignment: .leading) {
      FlagTopView( )
      FlagButtonView(selectedTab: $selectedTab)
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
  @State var filterWidth = "2.7k"
  @State var sliceLetter = "A"
  
  @State var nb = false
  @State var nr = true
  @State var anf = false
  @State var qsk = true
  
  @State var sMeterValue: CGFloat = 10.0

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 3) {
        Image(systemName: "x.circle").frame(width: 25, height: 25)
        Picker("", selection: $selectedRxAntenna) {
          ForEach(rxAntennas, id: \.self) {
            Text($0).font(.system(size: 8))
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        
        Picker("", selection: $selectedTxAntenna) {
          ForEach(txAntennas, id: \.self) {
            Text($0).font(.system(size: 8))
          }
        }
        .labelsHidden()
        
        Text(filterWidth)
        Text("SPLIT").font(.title2)
        Text("TX").font(.title2)
        Text(sliceLetter).font(.title2)
      }
      .padding(.top, 10)
      
      HStack(spacing: 3) {
        Image(systemName: "lock").frame(width: 25, height: 25)

        Group {
          Toggle("NB", isOn: $nb)
          Toggle("NR", isOn: $nr)
          Toggle("ANF", isOn: $anf)
          Toggle("QSK", isOn: $qsk)
        }
        .font(.system(size: 8))
        .toggleStyle(.button)

        TextField(
          "Frequency",
          value: $frequency,
          formatter: NumberFormatter()
        )
        .font(.title2)
        .multilineTextAlignment(.trailing)
      }
      LevelIndicatorView(level: sMeterValue, style: sMeterStyle)
    }
    .frame(height: 90)
  }
}

struct FlagButtonView: View {
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
      .padding(.horizontal, 10)
      .frame(width: 275, height: 200)
  }
}

struct FlagTopView_Previews: PreviewProvider {
  static var previews: some View {
    FlagTopView()
      .padding(.horizontal, 10)
      .frame(width: 275, height: 90)
  }
}

struct FlagButtonView_Previews: PreviewProvider {
  static var previews: some View {
    FlagButtonView(selectedTab: .constant(0))
      .padding(.horizontal, 10)
      .frame(width: 275, height: 110)
    FlagButtonView(selectedTab: .constant(1))
      .padding(.horizontal, 10)
      .frame(width: 275, height: 130)
    FlagButtonView(selectedTab: .constant(2))
      .padding(.horizontal, 10)
      .frame(width: 275, height: 110)
    FlagButtonView(selectedTab: .constant(3))
      .padding(.horizontal, 10)
      .frame(width: 275, height: 110)
    FlagButtonView(selectedTab: .constant(4))
      .padding(.horizontal, 10)
      .frame(width: 275, height: 110)
  }
}
