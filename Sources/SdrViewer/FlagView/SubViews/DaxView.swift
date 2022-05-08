//
//  DaxView.swift
//  
//
//  Created by Douglas Adams on 4/27/22.
//

import SwiftUI

struct DaxView: View {
  
  @State var selectedChannel = "none"
  @State var channel = [
    "none",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8"
  ]
  
  var body: some View {
    HStack {
      Picker("DAX Channel", selection: $selectedChannel) {
        ForEach(channel, id: \.self) {
          Text($0)
        }
      }.frame(width: 200)
    }
    .padding(.horizontal)
    .frame(height: 80)
  }
}

struct DaxView_Previews: PreviewProvider {
  static var previews: some View {
    DaxView()
      .frame(width: 275, height: 80)
  }
}
