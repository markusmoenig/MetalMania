//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

public class MMTileMapData  : Decodable {
    
    public var name         : String = ""

    public var tileWidth    : Int = 0
    public var tileHeight   : Int = 0

    public var columns      : Int = 0

    public var imageName    : String = ""

    private enum CodingKeys : String, CodingKey {
        case name
        case tilewidth
        case tileheight
        case columns
        case image
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //id = try container.decode(UUID.self, forKey: .id)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
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
        
        //children = try container.decode([SignedObject]?.self, forKey: .children)
        //code = try container.decode(Data?.self, forKey: .code)
        
        //session = "__project_session\(SignedObject.sessionCounter)"
    }
}