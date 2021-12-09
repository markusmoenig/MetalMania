//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

public class MMTileMapLayerData  : Decodable {
    
    public enum LayerType {
        case tile
        case objectGroup
    }
    
    public var name         : String = ""
    
    public var type         : LayerType = .tile

    public var id           : Int = 0

    public var x            : Int = 0
    public var y            : Int = 0
    
    public var width        : Int = 0
    public var height       : Int = 0

    public var opacity      : Float = 1
    public var visible      : Bool = false

    /// The tile data
    public var data         : [Int] = []

    /// The object data
    public var objects      : [MMTileObjectData] = []
    
    private enum CodingKeys : String, CodingKey {
        case name
        case type
        case id
        case x
        case y
        case width
        case height
        case data
        case opacity
        case visible
        case objects
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        }
        
        if let layertype = try container.decodeIfPresent(String.self, forKey: .type) {
            if layertype == "tilelayer" {
                type = .tile
            } else
            if layertype == "objectgroup" {
                type = .objectGroup
            }
        }
        
        if let id = try container.decodeIfPresent(Int.self, forKey: .id) {
            self.id = id
        }
        
        if let opacity = try container.decodeIfPresent(Float.self, forKey: .opacity) {
            self.opacity = opacity
        }
        
        if let visible = try container.decodeIfPresent(Bool.self, forKey: .visible) {
            self.visible = visible
        }
        
        if let x = try container.decodeIfPresent(Int.self, forKey: .x) {
            self.x = x
        }
        if let y = try container.decodeIfPresent(Int.self, forKey: .y) {
            self.y = y
        }
        if let width = try container.decodeIfPresent(Int.self, forKey: .width) {
            self.width = width
        }
        if let height = try container.decodeIfPresent(Int.self, forKey: .height) {
            self.height = height
        }
        
        if let data = try container.decodeIfPresent([Int].self, forKey: .data) {
            self.data = data
        }
        
        if let objects = try container.decodeIfPresent([MMTileObjectData].self, forKey: .objects) {
            self.objects = objects
        }
    }
}
