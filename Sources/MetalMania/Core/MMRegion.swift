//
//  MMRegion.swift
//  Framework
//
//  Created by Markus Moenig on 04.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

open class MMRegion
{
    public enum MMRegionType
    {
        case left, top, right, bottom, editor
    }
    
    public var rect         : MMRect
    public let mmView       : MMView
    
    public let type         : MMRegionType
    
    public let widget       : MMWidget?

    public init(_ view: MMView, type: MMRegionType, widget: MMWidget? = nil)
    {
        mmView = view
        rect = MMRect()
        
        self.widget = widget
        self.type = type
        
        if let widget = widget {
            registerWidgets(widgets: widget)
        }
    }
    
    open func build()
    {
        if let widget = widget {
            widget.rect.copy(rect)
            widget.draw()
        }
    }
    
    public func layoutH( startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var x : Float = startX
        for widget in widgets {
            widget.rect.x = x
            widget.rect.y = startY
            x += widget.rect.width + spacing
        }        
    }
    
    public func layoutHFromRight( startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var x : Float = startX
        for widget in widgets.reversed() {
            widget.rect.y = startY
            x -= widget.rect.width
            widget.rect.x = x
            x -= spacing
        }
    }
    
    public func layoutV( startX: Float, startY: Float, spacing: Float, widgets: MMWidget... )
    {
        var y : Float = startY
        for widget in widgets {
            widget.rect.x = startX
            widget.rect.y = y
            y += widget.rect.height + spacing
        }
    }
    
    public func registerWidgets( widgets: MMWidget... )
    {
        for widget in widgets {
            mmView.registerWidget(widget)
        }
    }
    
    public func resize(width: Float, height: Float)
    {
    }
}
