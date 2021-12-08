//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

public class MMTileSetData  : Decodable {
    
    public enum Orientation {
        case orthogonal
    }
    
    public enum Order {
        case rightDown
    }
    
    public var name         : String = ""

    public var tileWidth    : Int = 0
    public var tileHeight   : Int = 0

    public var columns      : Int = 0

    public var imageName    : String = ""
    
    public var orientation  : Orientation = .orthogonal
    public var order        : Order = .rightDown

    private enum CodingKeys : String, CodingKey {
        case name
        case tilewidth
        case tileheight
        case columns
        case image
        case orientation
        case order
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        }
        
        if let orientation = try container.decodeIfPresent(String.self, forKey: .orientation) {
            if orientation == "orthogonal" {
                self.orientation = .orthogonal
            }
        }
        
        if let order = try container.decodeIfPresent(String.self, forKey: .order) {
            if order == "right-down" {
                self.order = .rightDown
            }
        }
        
        if let imageName = try container.decodeIfPresent(String.self, forKey: .image) {
            self.imageName = imageName
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

/// The reference to a MMTileSet inside a MMTileMap
public class MMTileSetRefData  : Decodable {
    
    public var source        : String = ""
    public var firstgid      : Int = 0

    private enum CodingKeys : String, CodingKey {
        case source
        case firstgid
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let source = try container.decodeIfPresent(String.self, forKey: .source) {
            self.source = source
            let array = source.split(separator: ".")
            if array.count == 2 {
                self.source = String(array[0])
            }
        }
        
        if let firstgid = try container.decodeIfPresent(Int.self, forKey: .firstgid) {
            self.firstgid = firstgid
        }
    }
}

