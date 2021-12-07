//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

public class MMTileMapData  : Decodable {
    
    public var name         : String = ""

    public var width        : Int = 0
    public var height       : Int = 0
    
    public var tileWidth    : Int = 0
    public var tileHeight   : Int = 0

    public var columns      : Int = 0

    public var imageName    : String = ""
    
    public var layers       : [MMTileMapLayerData] = []
    public var tilesets     : [MMTileSetRefData] = []

    private enum CodingKeys : String, CodingKey {
        case name
        case width
        case height
        case tilewidth
        case tileheight
        case columns
        case image
        case layers
        case tilesets
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        }
        
        if let layers = try container.decodeIfPresent([MMTileMapLayerData].self, forKey: .layers) {
            self.layers = layers
        }
        
        if let tilesets = try container.decodeIfPresent([MMTileSetRefData].self, forKey: .tilesets) {
            self.tilesets = tilesets
        }
        
        if let imageName = try container.decodeIfPresent(String.self, forKey: .image) {
            self.imageName = imageName
        }
        
        if let width = try container.decodeIfPresent(Int.self, forKey: .width) {
            self.width = width
        }
        if let height = try container.decodeIfPresent(Int.self, forKey: .height) {
            self.height = height
        }
        
        if let tileWidth = try container.decodeIfPresent(Int.self, forKey: .tilewidth) {
            self.tileWidth = tileWidth
        }
        if let tileHeight = try container.decodeIfPresent(Int.self, forKey: .tileheight) {
            self.tileHeight = tileHeight
        }
        
        if let columns = try container.decodeIfPresent(Int.self, forKey: .columns) {
            self.columns = columns
        }
    }
}
