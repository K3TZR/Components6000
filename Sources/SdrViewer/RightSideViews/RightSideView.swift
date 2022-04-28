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
    @State var showPhne = false
    @State var showEq = false

    let width: CGFloat = 275
    let height: CGFloat = 240

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                ForEach(choices, id: \.self) { choice in
                    Button(choice) {
                        switch choice {

                        case "Rx":      showRx.toggle()
                        case "Tx":      showTx.toggle()
                        case "P/Cw":    showPcw.toggle()
                        case "Phne":    showPhne.toggle()
                        case "Eq":      showEq.toggle()
                        default:        showRx.toggle()
                        }
                    }
                }
            }
            Divider()
            ScrollView([.vertical]) {
                if showRx { FlagView() }
                if showTx { SideTxView(width: width, height: height) }
                if showPcw { SidePcwView(width: width, height: height) }
                if showPhne { SidePhneView(width: width, height: height) }
                if showEq { EqView() }
            }
        }
//        .padding()
    }
}

struct SideView_Previews: PreviewProvider {
    static var previews: some View {
        RightSideView()
    }
}

struct SideRxView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("Side Rx View")
            .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        Divider()
    }
}

struct SideTxView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("Side Tx View")
            .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        Divider()
    }
}

struct SidePcwView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("Side Pcw View")
            .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        Divider()
    }
}

struct SidePhneView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("Side Phne View")
            .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        Divider()
    }
}

struct SideEqView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("Side Eq View")
            .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        Divider()
    }
}
