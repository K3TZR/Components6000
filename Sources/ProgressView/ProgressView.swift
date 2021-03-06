//
//  ProgressView.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 3/23/22.
//
import ComposableArchitecture
import SwiftUI

public struct ProgressView: View {
  let store: Store<ProgressState, ProgressAction>

  public init(store: Store<ProgressState, ProgressAction>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Group {
          Text(viewStore.heading)
          Spacer()
          Text(viewStore.msg ?? "")
        }
        .multilineTextAlignment(.center)

        Spacer()
        if viewStore.duration != nil { ProgressBar(value: viewStore.value) }
        Spacer()
        Button("Cancel") { viewStore.send(.cancel) }
      }
      .onAppear() { if viewStore.duration != nil { viewStore.send(.startTimer) } }
      .padding()
      .border(.red)
    }
  }
}

public struct ProgressView_Previews: PreviewProvider {
  public static var previews: some View {
      ProgressView(
        store: Store(
          initialState: ProgressState(),
          reducer: progressReducer,
          environment: ProgressEnvironment()
        )
      )
    }
}

public struct ProgressBar: View {
  var value: Float
  
  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
          .opacity(0.3)
          .foregroundColor(.gray)
        
        Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
          .foregroundColor(.blue)
          .animation(.linear)
      }
      .cornerRadius(45.0)
    }
  }
}
