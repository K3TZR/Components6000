//
//  XritView.swift
//  
//
//  Created by Douglas Adams on 4/27/22.
//

import SwiftUI

struct XritView: View {
  
  @State var ritOffset = 0
  @State var xitOffset = 0
  @State var ritOffsetString = "0"
  @State var xitOffsetString = "0"
  @State var tuningStep = 0
  @State var tuningStepString = "0"
  
  let buttonWidth: CGFloat = 25
  //    let smallButtonWidth: CGFloat = 10
  
  var body: some View {
    VStack {
      HStack {
        VStack {
          Button(action: {}) {Text("RIT").frame(width: buttonWidth)}
          HStack(spacing: -10) {
            TextField("offset", text: $ritOffsetString)
//              .modifier(ClearButton(boundText: $ritOffsetString, trailing: false))
            
            Stepper("", value: $ritOffset, in: 0...10000)
          }.multilineTextAlignment(.trailing)
        }
        
        VStack {
          Button(action: {}) {Text("XIT").frame(width: buttonWidth)}
          HStack(spacing: -10)  {
            TextField("offset", text: $xitOffsetString)
//              .modifier(ClearButton(boundText: $xitOffsetString, trailing: false))
            
            Stepper("", value: $xitOffset, in: 0...10000)
          }.multilineTextAlignment(.trailing)
        }
      }
      
      HStack(spacing: 20) {
        Text("Tuning step")
        HStack(spacing: -10) {
          TextField("step", text: $tuningStepString)
//            .modifier(ClearButton(boundText: $tuningStepString, trailing: false))
          Stepper("", value: $tuningStep, in: 0...100000)
        }
      }.multilineTextAlignment(.trailing)
    }
    .padding(.horizontal)
    .frame(height: 80)
  }
}

struct XritView_Previews: PreviewProvider {
    static var previews: some View {
      XritView()
        .frame(width: 275, height: 80)
    }
}
