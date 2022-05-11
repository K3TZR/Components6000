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
  @State var showPh1 = false
  @State var showPh2 = false
  @State var showCw = false
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
          Toggle("Ph1", isOn: $showPh1)
          Toggle("Ph2", isOn: $showPh2)
          Toggle("Cw", isOn: $showCw)
          Toggle("Eq", isOn: $showEq)
        }
        .toggleStyle(.button)
      }
      Divider()
      ScrollView([.vertical]) {
        if showRx { FlagView() }
        if showTx { TxView() }
        if showPh1 { Ph1View() }
        if showPh2 { Ph2View() }
        if showCw { CwView() }
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
