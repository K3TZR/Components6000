//
//  SdrView.swift
//  
//
//  Created by Douglas Adams on 4/21/22.
//

import SwiftUI

public struct SdrView: View {
  
  public init() {}
  
  public var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          Image(systemName: "sidebar.left")
            .font(.system(size: 24, weight: .regular))
        }
        ToolbarItemGroup(placement: .principal) {
          Button("Connect") {}
            .keyboardShortcut(.defaultAction)
          
          Button("Pan") {  }
          Button("Tnf") { }
          Button("Marker") { }
          Button("Rcvd Audio") { }
          Button("Xmit Audio") { }
        }
        ToolbarItemGroup(placement: .principal) {
          Image(systemName: "speaker.wave.2.circle")
            .font(.system(size: 24, weight: .regular))
          Slider(value: .constant(50), in: 0...100, step: 1)
            .frame(width: 100)
          Image(systemName: "speaker.wave.2.circle")
            .font(.system(size: 24, weight: .regular))
          Slider(value: .constant(75), in: 0...100, step: 1)
            .frame(width: 100)
          Spacer()
          Image(systemName: "sidebar.right")
            .font(.system(size: 24, weight: .regular))
        }
      }

  }
}

public struct SdrView_Previews: PreviewProvider {
  public static var previews: some View {
    SdrView()
  }
}
