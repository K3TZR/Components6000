//
//  SettingsView.swift
//  Components6000/SdrView
//
//  Created by Douglas Adams on 3/28/21.
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import SwiftUI

public struct SettingsView: View {
  
  public init() {}
  
  public var body: some View {
    TabView {
      RadioSettingsView()
        .tabItem {
          Text("Radio")
          Image(systemName: "antenna.radiowaves.left.and.right")
        }.padding(.horizontal, 10)
      
      NetworkSettingsView()
        .tabItem {
          Text("Network")
          Image(systemName: "wifi")
        }
      GpsSettingsView()
        .tabItem {
          Text("Gps")
          Image(systemName: "globe")
        }
      TxSettingsView()
        .tabItem {
          Text("Tx")
          Image(systemName: "bolt.horizontal")
        }
      PhoneCwSettingsView()
        .tabItem {
          Text("Phone/Cw")
          Image(systemName: "mic")
        }
      RxSettingsView()
        .tabItem {
          Text("Rx")
          Image(systemName: "headphones")
        }
      FiltersSettingsView()
        .tabItem {
          Text("Filters")
          Image(systemName: "camera.filters")
        }
      XvtrSettingsView()
        .tabItem {
          Text("Xvtr")
          Image(systemName: "arrow.up.arrow.down.circle")
        }
      ColorsSettingsView()
        .tabItem {
          Text("Colors")
          Image(systemName: "eyedropper")
        }
        .onDisappear(perform: {
          // close the ColorPicker (if open)
          if NSColorPanel.shared.isVisible {
              NSColorPanel.shared.performClose(nil)
          }
        })
      InfoSettingsView()
        .tabItem {
          Text("Info")
          Image(systemName: "info.circle")
        }
    }
    .frame(minWidth: 600, maxWidth: 600, minHeight: 400, maxHeight: 400)
  }
}

public struct SettingsView_Previews: PreviewProvider {
  public static var previews: some View {
    SettingsView()
  }
}
