//
//  PickerHeaderView.swift
//  
//
//  Created by Douglas Adams on 1/9/22.
//

import SwiftUI
import ComposableArchitecture

import Shared

// ----------------------------------------------------------------------------
// MARK: - View

struct PickerHeaderView: View {
  let connectionType: ConnectionType

  var body: some View {
    VStack {
      Text("Select a \(connectionType.rawValue.uppercased())")
        .font(.title)
        .padding(.bottom, 10)

      Text("Click on a \(connectionType.rawValue.uppercased()) in the list below")
        .font(.title3)
        .padding(.bottom, 10)

      HStack(spacing: 0) {
        Group {
          Text("Type")
          Text("Name")
          Text("Status")
          Text("Station(s)")
        }
        .frame(width: 140, alignment: .leading)
      }
    }
    .font(.title2)
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct PickerHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    PickerHeaderView(connectionType: .gui)
      .previewDisplayName("Radio Picker")

    PickerHeaderView(connectionType: .nonGui)
      .previewDisplayName("Station Picker")
  }
}
