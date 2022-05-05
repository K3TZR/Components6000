//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 4/29/22.
//

import SwiftUI

struct TxView: View {
    var body: some View {
      VStack {
        Text("Tx View")
        Spacer()
        Divider().background(.blue)
      }
    }
}

struct TxView_Previews: PreviewProvider {
    static var previews: some View {
      TxView()
    }
}
