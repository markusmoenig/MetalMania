//
//  MMTileSet.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import MetalKit

/// A reference to a single tile
public struct MMTile {
    weak var texture        : MTLTexture? = nil
    var subRect             : MMRect? = nil
}

/// A tileset
open class MMTileSet {
    
    let mmView              : MMView
    
    var fileName            : String
    
    var refCount            : Int = 0
    
    public var texture      : MTLTexture? = nil
    public var tileSetData  : MMTileSetData! = nil
    
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
        
        return MMTile(texture: tileTexture, subRect: tileSubRect)
    }
}
