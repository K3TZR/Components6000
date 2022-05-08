//
//  SideView.swift
//  
//
//  Created by Douglas Adams on 4/27/22.
//

import SwiftUI

struct RightSideView: View {
  let choices = ["Rx", "Tx", "P/Cw", "Phne", "Eq"]
  
  @State var showRx = false
  @State var showTx = false
  @State var showPcw = false
  @State var showPhone = false
  @State var showPhne = false
  @State var showEq = false
  
  @State var isCwMode = true
  
  let width: CGFloat = 275
  let height: CGFloat = 240
  
  var body: some View {
    VStack(alignment: .center) {
      
      HStack {
        Group {
          Toggle("Rx", isOn: $showRx)
          Toggle("Tx", isOn: $showTx)
          Toggle("P/CW", isOn: $showPcw)
          Toggle("Phne", isOn: $showPhne)
          Toggle("Eq", isOn: $showEq)
        }
        .toggleStyle(.button)
      }
      Divider()
      ScrollView([.vertical]) {
        if showRx { FlagView() }
        if showTx { TxView() }
        if showPcw  {
          if isCwMode {
            CwView()
          } else {
            PhoneView()
          }
        }
        if showPhne { PhneView() }
        if showEq { EqView() }
      }
    }
    //        .padding()
  }
}


struct SideView_Previews: PreviewProvider {
  static var previews: some View {
    RightSideView()
      .frame(width: 260)
  }
}

//struct SideRxView: View {
//  let width: CGFloat
//  let height: CGFloat
//
//  var body: some View {
//    Text("Side Rx View")
//      .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
//    Divider()
//  }
//}
//
//struct SideTxView: View {
//  let width: CGFloat
//  let height: CGFloat
//
//  var body: some View {
//    Text("Side Tx View")
//      .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
//    Divider()
//  }
//}
//
//struct SidePcwView: View {
//  let width: CGFloat
//  let height: CGFloat
//
//  var body: some View {
//    Text("Side Pcw View")
//      .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
//    Divider()
//  }
//}
//
//struct SidePhneView: View {
//  let width: CGFloat
//  let height: CGFloat
//
//  var body: some View {
//    Text("Side Phne View")
//      .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
//    Divider()
//  }
//}
//
//struct SideEqView: View {
//  let width: CGFloat
//  let height: CGFloat
//
//  var body: some View {
//    Text("Side Eq View")
//      .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
//    Divider()
//  }
//}
