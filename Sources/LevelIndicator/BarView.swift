////
////  BarView.swift
////  CustomLevelIndicator
////
////  Created by Douglas Adams on 3/4/19.
////  Copyright © 2019 Douglas Adams. All rights reserved.
////
//
//import Cocoa
//
//final class BarView: NSView {
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Public properties
//  
//  public var level: CGFloat = 0.0
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Private properties
//  
//  private var _path = NSBezierPath()
//  private var _params: IndicatorParams!
//  private var _gradient: NSGradient!
//  private var _viewType: Int!
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Initialization
//  
//  /// Initialize the Bar view
//  ///
//  /// - Parameters:
//  ///   - frameRect:              the rect of the view
//  ///   - params:                 a Params struct
//  ///
//  convenience init(frame frameRect: NSRect, params: IndicatorParams, viewType: Int, gradient: NSGradient) {
//    
//    self.init(frame: frameRect)
//    _params = params
//    _viewType = viewType
//    
//    _gradient = gradient
//  }
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Overridden methods
//  
//  /// Draw in the specified rect
//  ///
//  /// - Parameter dirtyRect:        the rect to draw in
//  ///
//  override func draw(_ dirtyRect: NSRect) {
//    super.draw(dirtyRect)
//
//    // calculate the percent
//    let levelPercent = (level - _params.origin) / (_params.end - _params.origin)
//    
//    guard levelPercent <= 100 && levelPercent >= 0 else { return }
//    
//    // create the clipping rect
//    NSBezierPath.clip( levelClipRect(levelPercent: levelPercent, rect: dirtyRect, type: _viewType, flipped: _params.isFlipped))
//    
//    // add the gradient (subject to the clip area)
//    _path.append( gradientBar(at: NSRect(x: 0, y: 0, width: frame.width, height: frame.height),
//                              gradient: _gradient,
//                              flipped: _params.isFlipped) )
//    // draw
//    _path.strokeRemove()
//  }
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Private methods
//  
//  /// Calculate a clipping rect for the bar
//  ///
//  /// - Parameters:
//  ///   - levelPercent:             the level as a percentage
//  ///   - rect:                     the Bar rect
//  ///   - flipped:                  true = flipped (i.e. right to left)
//  /// - Returns:                    the clipping rect
//  ///
//  private func levelClipRect(levelPercent: CGFloat, rect: NSRect, type: Int, flipped: Bool) -> NSRect {
//    
//    // Level or Peak?
//    let width = ( type == LevelIndicator.kLevelView ? levelPercent * rect.width : LevelIndicator.kPeakWidth )
//    
//    // Flipped or Normal?
//    return flipped ?
//      NSRect(x: (1.0 - levelPercent) * rect.width, y: 0, width: width, height: rect.height) :
//      NSRect(x: 0, y: 0, width: width, height: rect.height)
//  }
//  /// Create a gradient filled rect area
//  ///
//  /// - Parameters:
//  ///   - rect:                   the area
//  ///   - color:                  an NSGradient
//  /// - Returns:                  the filled NSBezierPath
//  ///
//  private func gradientBar(at rect: NSRect, gradient: NSGradient, flipped: Bool) -> NSBezierPath {
//    
//    // Flipped or Normal?
//    let adjustedRect = flipped ? NSRect(x: rect.width, y: 0, width: -rect.width, height: rect.height) : rect
//    
//    // create a path with the specified rect
//    let path = NSBezierPath(rect: rect)
//    
//    // fill it with the gradient
//    gradient.draw(in: adjustedRect, angle: 0.0)
//    
//    return path
//  }
//}
//
//extension NSBezierPath {
//    
//    /// Draw a Horizontal line
//    ///
//    /// - Parameters:
//    ///   - y:            y-position of the line
//    ///   - x1:           starting x-position
//    ///   - x2:           ending x-position
//    ///
//    func hLine(at y: CGFloat, fromX: CGFloat, toX: CGFloat) {
//        move( to: CGPoint( x: fromX, y: y ) )
//        line( to: CGPoint( x: toX, y: y ) )
//    }
//    /// Draw a Vertical line
//    ///
//    /// - Parameters:
//    ///   - x:            x-position of the line
//    ///   - y1:           starting y-position
//    ///   - y2:           ending y-position
//    ///
//    func vLine(at x: CGFloat, fromY: CGFloat, toY: CGFloat) {
//        move( to: CGPoint( x: x, y: fromY) )
//        line( to: CGPoint( x: x, y: toY ) )
//    }
//    
//    /// Fill a Rectangle
//    ///
//    /// - Parameters:
//    ///   - rect:           the rect
//    ///   - color:          the fill color
//    ///
//    func fillRect( _ rect: NSRect, withColor color: NSColor, andAlpha alpha: CGFloat = 1) {
//        // fill the rectangle with the requested color and alpha
//        color.withAlphaComponent(alpha).set()
//        appendRect( rect )
//        fill()
//    }
//    
//    /// Draw a triangle
//    ///
//    ///
//    /// - Parameters:
//    ///   - center:         x-posiion of the triangle's center
//    ///   - topWidth:       width of the triangle
//    ///   - triangleHeight: height of the triangle
//    ///   - topPosition:    y-position of the top of the triangle
//    ///
//    func drawTriangle(at center: CGFloat, topWidth: CGFloat, triangleHeight: CGFloat, topPosition: CGFloat) {
//        move(to: NSPoint(x: center - (topWidth/2), y: topPosition))
//        line(to: NSPoint(x: center + (topWidth/2), y: topPosition))
//        line(to: NSPoint(x: center, y: topPosition - triangleHeight))
//        line(to: NSPoint(x: center - (topWidth/2), y: topPosition))
//        fill()
//    }
//    
//    /// Draw an Oval inside a Rectangle
//    ///
//    /// - Parameters:
//    ///   - rect:           the rect
//    ///   - color:          the color
//    ///   - alpha:          the alpha value
//    ///
//    func drawCircle(in rect: NSRect, color: NSColor, andAlpha alpha: CGFloat = 1) {
//        appendOval(in: rect)
//        color.withAlphaComponent(alpha).set()
//        fill()
//    }
//    
//    /// Draw a Circle
//    ///
//    /// - Parameters:
//    ///   - point:          the center of the circle
//    ///   - radius:         the radius of the circle
//    ///
//    func drawCircle(at point: NSPoint, radius: CGFloat) {
//        let rect = NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
//        appendOval(in: rect)
//    }
//    
//    /// Draw an X
//    ///
//    /// - Parameters:
//    ///   - point:          the center of the X
//    ///   - halfWidth:      the half width of the X
//    ///
//    func drawX(at point: NSPoint, halfWidth: CGFloat) {
//        move(to: NSPoint(x: point.x - halfWidth, y: point.y + halfWidth))
//        line(to: NSPoint(x: point.x + halfWidth, y: point.y - halfWidth))
//        move(to: NSPoint(x: point.x + halfWidth, y: point.y + halfWidth))
//        line(to: NSPoint(x: point.x - halfWidth, y: point.y - halfWidth))
//    }
//    
//    /// Crosshatch an area
//    ///
//    /// - Parameters:
//    ///   - rect:           the rect
//    ///   - color:          a color
//    ///   - depth:          an integer ( 1, 2 or 3)
//    ///   - linewidth:      width of the crosshatch lines
//    ///   - multiplier:     lines per depth
//    ///
//    func crosshatch(_ rect: NSRect, color: NSColor, depth: Int, twoWay: Bool = false, linewidth: CGFloat = 1, multiplier: Int = 5) {
//        if depth == 1 || depth > 3 { return }
//        
//        // calculate the number of lines to draw
//        let numberOfLines = depth * multiplier * (depth == 2 ? 1 : 2)
//        
//        // calculate the line increment
//        let incr: CGFloat = rect.size.height / CGFloat(numberOfLines)
//        
//        // set color and line width
//        color.set()
//        lineWidth = linewidth
//        
//        // draw the crosshatch
//        for i in 0..<numberOfLines {
//            move( to: CGPoint( x: rect.origin.x, y: CGFloat(i) * incr))
//            line(to: CGPoint(x: rect.origin.x + rect.size.width, y: CGFloat(i+1) * incr))
//        }
//        if twoWay {
//            // draw the opposite crosshatch
//            for i in 0..<numberOfLines {
//                move( to: CGPoint( x: rect.origin.x + rect.size.width, y: CGFloat(i) * incr))
//                line(to: CGPoint(x: rect.origin.x, y: CGFloat(i+1) * incr))
//            }
//        }
//    }
//    /// Stroke and then Remove all points
//    ///
//    func strokeRemove() {
//        stroke()
//        removeAllPoints()
//    }
//}
