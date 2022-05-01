//
//  LevelIndicatorView.swift
//  Components6000/LevelIndicator
//
//  Created by Douglas Adams on 4/29/22.
//

import Foundation
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public struct Tick {
  public var position: CGFloat  // 0...1
  public var label: String

  public init
  (
    position: CGFloat,
    label: String
  )
  {
    self.position = position
    self.label = label
  }
}

public enum IndicatorStyle {
  case standard
  case flipped
  case sMeter
}

public struct IndicatorParams {
  var width: CGFloat
  var height: CGFloat
  var style: IndicatorStyle
  var warningLevel: CGFloat     // 0...1
  var criticalLevel: CGFloat    // 0...1
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color
  var tickColor: Color
  var legendFont: Font
  var ticks: [Tick]
  
  public init
  (
    width: CGFloat = 200,
    height: CGFloat = 20,
    style: IndicatorStyle = .standard,
    warningLevel: CGFloat = 0.6,
    criticalLevel: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .green,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .white,
    tickColor: Color = .black,
    legendFont: Font = .custom("Monaco", fixedSize: 8),
    ticks: [Tick] = []
  )
  {
    self.width = width
    self.height = height
    self.style = style
    self.warningLevel = warningLevel
    self.criticalLevel = criticalLevel
    self.backgroundColor = backgroundColor
    self.normalColor = normalColor
    self.warningColor = warningColor
    self.criticalColor = criticalColor
    self.borderColor = borderColor
    self.tickColor = tickColor
    self.legendFont = legendFont
    self.ticks = ticks
    
    
  }
//
//  public mutating func calcOffsets() {
//
//    for (i, tick) in ticks.enumerated() {
////      let legendWidth = legendFont.textWidth(s: tick.label)
////      ticks[i].offset = (tick.position * width) - (CGFloat(i) * legendWidth)/2
//      ticks[i].offset = (tick.position * width) - (CGFloat(i) * 20)/2
//    }
//  }
}

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var level: CGFloat
  var params: IndicatorParams
  
  public init(
    level: CGFloat,
    params: IndicatorParams = IndicatorParams()
  )
  {
    self.level = min(level , 1.0)   // 0...1
    self.params = params

    self.params.warningLevel = (0...1).contains(params.warningLevel) ? params.warningLevel : 1
    self.params.criticalLevel = (params.warningLevel...1).contains(params.criticalLevel) ? params.criticalLevel : 1
  }
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 1) {
      LegendView(params: params)
      ZStack(alignment: .leading) {
        BarView(level: level, params: params)
        OutlineView(params: params)
        TickView(params: params)
      }
      .rotationEffect(.degrees( params.style == .flipped ? 180 : 0))
    }
  }
}

struct LegendView: View {
  var params: IndicatorParams
  
  func offset(_ position: CGFloat, _ style: IndicatorStyle) -> CGFloat {
    switch style {
    case .standard, .sMeter:
      return (position * params.width) - 13.0/2.0
    case .flipped:
      return ((1.0 - position) * params.width) - 13.0/2.0
    }
  }
  
  var body: some View {
        
    ZStack(alignment: .center) {
      ForEach(params.ticks, id:\.position) { tick in
        Text(tick.label).font(params.legendFont)
          .frame(alignment: .leading)
          .offset(x: offset(tick.position, params.style))
      }
    }
    //    .rotationEffect(.degrees(180))
    .frame(width: params.width, height: params.height, alignment: .leading)
    .padding(.horizontal, 10)
  }
}

struct TickView: View {
  var params: IndicatorParams

  var body: some View {
    
    
    Path { path in
      for tick in params.ticks {
        path.move(to: CGPoint(x: tick.position * params.width, y: 0))
        path.addLine(to: CGPoint(x: tick.position * params.width, y: params.height))
      }
    }
    .stroke(params.tickColor)
    .frame(width: params.width, height: params.height)
    .padding(.horizontal, 10)
  }
}

struct BarView: View {
  var level: CGFloat
  var params: IndicatorParams
  
  var body: some View {
    
    let segment0 = level > params.warningLevel ? params.warningLevel : level
    let segment1 = level > params.warningLevel ? min(level - params.warningLevel, params.criticalLevel - params.warningLevel) : 0
    let segment2 = level > params.criticalLevel ? level - params.criticalLevel : 0
    
    HStack(spacing: 0) {
      Rectangle()
        .frame(width: params.width * segment0, height:params.height)
        .foregroundColor(params.normalColor)
      Rectangle()
        .frame(width: params.width * segment1, height:params.height)
        .foregroundColor(params.warningColor)
      Rectangle()
        .frame(width: min(params.width * segment2, params.width * params.criticalLevel), height:params.height)
        .foregroundColor(params.criticalColor)
    }
    .padding(.horizontal, 10)
  }
}

struct OutlineView: View {
  var params: IndicatorParams
  
  var body: some View {
    
    Rectangle()
      .frame(width: params.width, height: params.height)
      .foregroundColor(params.backgroundColor)
      .border(params.borderColor)
      .padding(.horizontal, 10)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

struct LevelIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      
      LevelIndicatorView(level: 0.4,
                         params: IndicatorParams(height: 10,
                                                 style: .standard,
                                                 ticks:
                                                  [
                                                    Tick(position:0.0, label: "0"),
                                                    Tick(position:0.1, label: "10"),
                                                    Tick(position:0.3, label: "30"),
                                                    Tick(position:0.5, label: "50"),
                                                    Tick(position:0.7, label: "70"),
                                                    Tick(position:0.9, label: "90"),
                                                    Tick(position:1.0, label: "100")
                                                  ]
                                                )
      )
      
      
      LevelIndicatorView(level: 0.4,
                         params: IndicatorParams(height: 10,
                                                 style: .flipped,
                                                 ticks:
                                                  [
                                                    Tick(position:0.0, label: "0"),
                                                    Tick(position:0.1, label: "10"),
                                                    Tick(position:0.3, label: "30"),
                                                    Tick(position:0.5, label: "50"),
                                                    Tick(position:0.7, label: "70"),
                                                    Tick(position:0.9, label: "90"),
                                                    Tick(position:1.0, label: "100")
                                                  ]
                                                )
      )
      LevelIndicatorView(level: 0.3)
      LevelIndicatorView(level: 0.4, params: IndicatorParams(style: .flipped,
                                                             borderColor: .yellow))
      LevelIndicatorView(level: 0.5)
      LevelIndicatorView(level: 0.55)
      LevelIndicatorView(level: 0.6)
      LevelIndicatorView(level: 0.65)
    }
    Group {
      LevelIndicatorView(level: 0.7)
      LevelIndicatorView(level: 0.75)
      LevelIndicatorView(level: 0.8)
      LevelIndicatorView(level: 0.85)
      LevelIndicatorView(level: 0.9)
      LevelIndicatorView(level: 0.95, params: IndicatorParams(height: 10,
                                                              style: .flipped,
                                                              ticks:
                                                               [
                                                                 Tick(position:0.0, label: "0"),
                                                                 Tick(position:0.1, label: "10"),
                                                                 Tick(position:0.3, label: "30"),
                                                                 Tick(position:0.5, label: "50"),
                                                                 Tick(position:0.7, label: "70"),
                                                                 Tick(position:0.9, label: "90"),
                                                                 Tick(position:1.0, label: "100")
                                                               ]
                                                             )
      )
//      LevelIndicatorView(level: 1.0)
      LevelIndicatorView(level: 1.05)
    }
    
    //    LevelIndicatorView(level: 0.4, style: .standardFlipped)
    //    LevelIndicatorView(level: 0.85)
    //    LevelIndicatorView(level: 0.95)
  }
}

struct BarView_Previews: PreviewProvider {
  static var previews: some View {
    BarView(level: 0.4, params: IndicatorParams())
  }
}

struct OutlineView_Previews: PreviewProvider {
  static var previews: some View {
    OutlineView(params: IndicatorParams())
  }
}

struct LegendView_Previews: PreviewProvider {
  static var previews: some View {
    LegendView(params: IndicatorParams(height: 10,
                                       ticks:
                                        [
                                          Tick(position:0.1, label: "10"),
                                          Tick(position:0.3, label: "30")
                                        ]))
    LegendView(params: IndicatorParams(height: 10,
                                       style: .flipped,
                                       ticks: [
                                        Tick(position:0.1, label: "10"),
                                        Tick(position:0.3, label: "30")
                                       ]))
  }
}

extension Font {

    public func textWidth(s: String) -> CGFloat
    {
        return s.size(withAttributes: [NSAttributedString.Key.font: self]).width
    }

}
