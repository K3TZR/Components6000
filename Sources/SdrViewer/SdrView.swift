//
//  SdrView.swift
//  
//
//  Created by Douglas Adams on 4/21/22.
//

import SwiftUI

public struct SdrView: View {
  
  @AppStorage(wrappedValue: false, "leftSideView") var leftSideView: Bool
  @AppStorage(wrappedValue: false, "rightSideView") var rightSideView: Bool
  @State var leftWidth: CGFloat = 75
  @State var rightWidth: CGFloat = 275
  @State var totalWidthMin: CGFloat = 500
  
  public init() {}
  
  public var body: some View {
    VStack {
      HStack(spacing: 0) {
        if leftSideView {
          LeftSideView()
            .frame(minWidth: leftWidth, maxWidth: leftWidth)
          Divider()
        }
        VSplitView {
          PanadapterContainerView()
          WaterfallContainerView()
        }.frame(minWidth: totalWidthMin - leftWidth - rightWidth,  maxWidth: .infinity, minHeight: 430)
        if rightSideView {
          Divider()
          RightSideView()
            .frame(minWidth: rightWidth, maxWidth: rightWidth)
        }
      }
      BottomButtonsView()
    }
    .frame(minWidth: totalWidthMin, maxWidth: .infinity)
        
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        Image(systemName: "sidebar.left")
          .font(.system(size: 24, weight: .regular))
          .onTapGesture(perform: {
            leftSideView.toggle()
          })
      }
      ToolbarItemGroup(placement: .principal) {
        Button("Connect") {}
          .keyboardShortcut(.defaultAction)
        
        Button("Pan") {}
        Button("Tnf") {}
        Button("Marker") {}
        Button("Rcvd Audio") {}
        Button("Xmit Audio") {}
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
        Button("Log View") { WindowChoice.LogViewer.open() }
        Image(systemName: "sidebar.right")
          .font(.system(size: 24, weight: .regular))
          .onTapGesture(perform: {
            rightSideView.toggle()
          })
      }
    }
  }
}

public struct SdrView_Previews: PreviewProvider {
  public static var previews: some View {
    SdrView()
  }
}

public enum WindowChoice: String, CaseIterable {
  case LogViewer
  case ProfileView
  case TxView
  case Ph1View
  case Ph2View
  case CwView
  case EqView

  public func open() {
    if let url = URL(string: "Sdr6000://\(self.rawValue)") {
      NSWorkspace.shared.open(url)
    }
  }
}
