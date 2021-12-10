//
//  MMTileSet.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import MetalKit

/// A reference to a single tile
public struct MMTile {
    
    // For display
    weak var texture        : MTLTexture? = nil
    var subRect             : MMRect? = nil
    
    // For reference    
    weak var tileSet        : MMTileSet? = nil
    var tileId              : Int = -1
}

/// A tileset
open class MMTileSet {
    
    let mmView              : MMView
    
    var fileName            : String
    
    var refCount            : Int = 0
    
    public var texture      : MTLTexture? = nil
    public var tileSetData  : MMTileSetData! = nil
    
    /// The references to the object group data for each tile
    public var objects      : [Int: MMTileObjectGroupData] = [:]
    
    public init(_ mmView: MMView, fileName: String) {
        self.mmView = mmView
        self.fileName = fileName
        
        if refCount == 0 {
            load()
        }
    }
    
    /// Load the tileset assets
    @discardableResult public func load() -> MMTileSetData? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = NSData(contentsOfFile: path)! as Data
            
            tileSetData = try? JSONDecoder().decode(MMTileSetData.self, from: data)

            if let tileSetData = tileSetData {
                
                if tileSetData.imageName.isEmpty == false {
                 
                    let array = tileSetData.imageName.split(separator: ".")
                    if array.count == 2 {
                        texture = mmView.loadTexture(String(array[0]), type: String(array[1]))
                    }
                }
                
                // Parse the object groups and store them for easier access
                for object in tileSetData.tileObjects {
                    objects[object.id] = object.objectGroup
                }
            }
            
            return tileSetData
        }
        return nil
    }
    
    /// Return the tile at the given grid id
    func getTile(id: Int) -> MMTile {
        
        var tileTexture : MTLTexture? = nil
        var tileSubRect : MMRect? = nil
                
        let tWidth = Float(tileSetData.tileWidth)
        let tHeight = Float(tileSetData.tileHeight)

        tileTexture = texture
        
        if tileSetData.order == .rightDown {
            
            let xOff = Float(id % tileSetData.columns)
            let yOff = Float(id / tileSetData.columns)

            tileSubRect = MMRect(xOff * tWidth, yOff * tWidth, tWidth, tHeight)
        }
        
        return MMTile(texture: tileTexture, subRect: tileSubRect, tileSet: self, tileId: id)
    }
}
