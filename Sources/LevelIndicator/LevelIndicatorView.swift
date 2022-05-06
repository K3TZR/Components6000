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
  public var value: CGFloat  // 0...1
  public var label: String?
  public var hideLine: Bool

  public init
  (
    value: CGFloat,
    label: String? = nil,
    hideLine: Bool = false
  )
  {
    self.value = value
    self.label = label
    self.hideLine = hideLine
  }
}

public struct IndicatorStyle {
  var width: CGFloat
  var height: CGFloat
  var isFlipped: Bool
  var min: CGFloat
  var max: CGFloat
  var warningLevel: CGFloat     // min...max
  var criticalLevel: CGFloat    // min...max
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color
  var tickColor: Color
  var legendFont: Font
  var legendColor: Color
  var ticks: [Tick]
  
  public init
  (
    width: CGFloat = 140,
    height: CGFloat = 10,
    isFlipped: Bool = false,
    min: CGFloat = 0.0,
    max: CGFloat = 1.0,
    warningLevel: CGFloat = 0.6,
    criticalLevel: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .green,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .blue,
    tickColor: Color = .blue,
    legendFont: Font = .custom("Monaco", fixedSize: 8),
    legendColor: Color = .orange,
    ticks: [Tick] = []
  )
  {
    self.width = width
    self.height = height
    self.isFlipped = isFlipped
    self.min = min
    self.max = max
    self.warningLevel = warningLevel
    self.criticalLevel = criticalLevel
    self.backgroundColor = backgroundColor
    self.normalColor = normalColor
    self.warningColor = warningColor
    self.criticalColor = criticalColor
    self.borderColor = borderColor
    self.tickColor = tickColor
    self.legendFont = legendFont
    self.legendColor = legendColor
    self.ticks = ticks
    
    
  }
}

public let rfPowerStyle = IndicatorStyle(
  width: 220,
  height: 30,
  isFlipped: false,
  max: 1.2,
  warningLevel: 1.0,
  criticalLevel: 1.1,
  legendFont: .custom("Monaco", fixedSize: 12),
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:0.1),
      Tick(value:0.2),
      Tick(value:0.3),
      Tick(value:0.4, label: "40"),
      Tick(value:0.50, label: "RF Pwr"),
      Tick(value:0.6),
      Tick(value:0.7),
      Tick(value:0.8, label: "80"),
      Tick(value:0.9),
      Tick(value:1.0, label: "100"),
      Tick(value:1.1),
      Tick(value:1.2, label: "120"),
    ]
)

public let swrStyle = IndicatorStyle(
  width: 220,
  height: 30,
  isFlipped: false,
  min: 1.0,
  max: 3.0,
  warningLevel: 2.0,
  criticalLevel: 2.5,
  legendFont: .custom("Monaco", fixedSize: 12),
  ticks:
    [
      Tick(value:1.0, label: "1"),
      Tick(value:1.25),
      Tick(value:1.5, label: "1.5"),
      Tick(value:1.75),
      Tick(value:2.0, label: "SWR"),
      Tick(value:2.25),
      Tick(value:2.5, label: "2.5"),
      Tick(value:2.75),
      Tick(value:3.0, label: "3"),
    ]
)

public let alcStyle = IndicatorStyle(
  width: 220,
  height: 30,
  isFlipped: false,
  min: 0.0,
  max: 1.0,
  warningLevel: 0.25,
  criticalLevel: 0.5,
  legendFont: .custom("Monaco", fixedSize: 12),
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:0.20),
      Tick(value:0.4),
      Tick(value:0.5, label: "ALC", hideLine: true),
      Tick(value:0.6),
      Tick(value:0.8),
      Tick(value:1.0, label: "100"),
    ]
)

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var level: CGFloat
  var style: IndicatorStyle
  
  public init(
    level: CGFloat,
    style: IndicatorStyle
  )
  {
    self.level = min(level , style.max)   // min...max
    self.style = style

    self.style.warningLevel = (style.min...style.max).contains(style.warningLevel) ? style.warningLevel : style.max
    self.style.criticalLevel = (style.warningLevel...style.max).contains(style.criticalLevel) ? style.criticalLevel : style.max
  }
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 0) {
      LegendView(style: style)
      ZStack(alignment: .bottomLeading) {
        BarView(level: level, style: style)
        OutlineView(style: style)
        TickView(style: style)
      }
      .rotationEffect(.degrees(style.isFlipped ? 180 : 0))
    }
    .frame(width: style.width, height: style.height, alignment: .leading)
    .padding(.horizontal, 10)
  }
}

struct LegendView: View {
  var style: IndicatorStyle
  
  // FIXME: FLIPPED
  
  var body: some View {
        
    ZStack(alignment: .leading) {
      ForEach(style.ticks, id:\.value) { tick in
        let tickLocation = (tick.value - style.min) * ((style.width) / (style.max - style.min))
        Text(tick.label ?? "").font(style.legendFont)
          .frame(alignment: .leading)
          .offset(x: style.isFlipped ? style.max - tickLocation : tickLocation)
      }
      .foregroundColor(style.legendColor)
    }
  }
}

struct BarView: View {
  var level: CGFloat
  var style: IndicatorStyle
  
  var body: some View {
    let valueRange = style.max - style.min

    HStack(spacing: 0) {
      Rectangle()
        .fill(style.normalColor)
        .frame(width: (style.width) * (style.warningLevel - style.min) / valueRange, alignment: .leading)
      Rectangle()
        .fill(style.warningColor)
        .frame(width: (style.width) * (style.criticalLevel - style.warningLevel) / valueRange, alignment: .leading)
      Rectangle()
        .fill(style.criticalColor)
        .frame(width: (style.width) * (style.max - style.criticalLevel) / valueRange, alignment: .leading)
    }
    .frame(width: (style.width) * (level - style.min) / valueRange, alignment: .leading)
    .clipped()
  }
}

struct TickView: View {
  var style: IndicatorStyle

  var body: some View {
    
    Path { path in
      for tick in style.ticks {
        if tick.hideLine == false {
          let tickLocation = (tick.value - style.min) * ((style.width) / (style.max - style.min))
          path.move(to: CGPoint(x: tickLocation , y: 0))
          path.addLine(to: CGPoint(x: tickLocation, y: style.height))
        }
      }
    }
    .stroke(style.tickColor)
  }
}

struct OutlineView: View {
  var style: IndicatorStyle
  
  var body: some View {
    
    Rectangle()
      .foregroundColor(style.backgroundColor)
      .border(style.borderColor)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

struct LevelIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
    LevelIndicatorView(level: 0.5, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 0.5")
    LevelIndicatorView(level: 1.0, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.0")
    LevelIndicatorView(level: 1.1, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.1")
    LevelIndicatorView(level: 1.2, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.2")

    Group {
      LevelIndicatorView(level: 1.5, style: swrStyle)
        .previewDisplayName("SWR @ 1.5")
      LevelIndicatorView(level: 2.0, style: swrStyle)
        .previewDisplayName("SWR @ 2.0")
      LevelIndicatorView(level: 2.5, style: swrStyle)
        .previewDisplayName("SWR @ 2.5")
      LevelIndicatorView(level: 3.0, style: swrStyle)
        .previewDisplayName("SWR @ 3.0")
    }

    LevelIndicatorView(level: 0.25, style: alcStyle)
      .previewDisplayName("ALC @ 0.25")
    LevelIndicatorView(level: 0.50, style: alcStyle)
      .previewDisplayName("ALC @ 0.50")
    LevelIndicatorView(level: 1.0, style: alcStyle)
      .previewDisplayName("ALC @ 1.0")
  }
}

struct LegendView_Previews: PreviewProvider {
  static var previews: some View {
    LegendView(style: rfPowerStyle)
      .previewDisplayName("Rf Power - Legend")
    LegendView(style: swrStyle)
      .previewDisplayName("SWR - Legend")
    LegendView(style: alcStyle)
      .previewDisplayName("ALC - Legend")
  }
}

struct BarView_Previews: PreviewProvider {
  static var previews: some View {
    BarView(level: 0.5, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 0.5 - Bar")
    BarView(level: 1.0, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.0 - Bar")
    BarView(level: 1.1, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.1 - Bar")
    BarView(level: 1.2, style: rfPowerStyle)
      .previewDisplayName("Rf Power @ 1.2 - Bar")

    BarView(level: 2.6, style: swrStyle)
      .previewDisplayName("SWR - Bar")
    BarView(level: 0.6, style: alcStyle)
      .previewDisplayName("ALC - Bar")
  }
}

struct TickView_Previews: PreviewProvider {
  static var previews: some View {
    TickView(style: rfPowerStyle)
      .previewDisplayName("Rf Power - Ticks")
    TickView(style: swrStyle)
      .previewDisplayName("SWR - Ticks")
    TickView(style: alcStyle)
      .previewDisplayName("ALC - Ticks")
  }
}

struct OutlineView_Previews: PreviewProvider {
  static var previews: some View {
    OutlineView(style: rfPowerStyle)
      .previewDisplayName("Rf Power - Outline")
    OutlineView(style: swrStyle)
      .previewDisplayName("SWR - Outline")
    OutlineView(style: alcStyle)
      .previewDisplayName("ALC - Outline")
  }
}
