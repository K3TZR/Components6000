//
//  PickerHeaderView.swift
//  
//
//  Created by Douglas Adams on 1/9/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct PickerHeaderView: View {
  let pickType: PickType

  var body: some View {
    VStack {
      Text("Select a \(pickType.rawValue)")
        .font(.title)
        .padding(.bottom, 10)

      Text("Click on a \(pickType == .radio ? "NAME" : "STATION" ) in the list below")
        .font(.title3)
        .padding(.bottom, 10)

      HStack(spacing: 0) {
        Group {
          Text("Default")
        }
        .font(.title2)
        .frame(width: 95, alignment: .leading)

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
    PickerHeaderView(pickType: .radio)
      .previewDisplayName("Radio Picker")

    PickerHeaderView(pickType: .station)
      .previewDisplayName("Station Picker")
  }
}
