//
//  MMTileSet.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import MetalKit

/// A reference to a single tile
public class MMTile {
    
    // For display
    let texture             : MTLTexture?
    let subRect             : MMRect?
    
    // For reference    
    let tileSet             : MMTileSet?
    let tileId              : Int
    
    // Optional Animation data
    var animation           : [MMTile]? = nil
    
    var currDuration        : Int = 0
    var currIndex           : Int = 0
    
    var duration            : Int = 10
    
    // Box2D body
    var box2DBody           : b2Body? = nil
        
    init(texture: MTLTexture? = nil, subRect: MMRect? = nil, tileSet: MMTileSet, tileId: Int) {
        self.texture = texture
        self.subRect = subRect
        self.tileSet = tileSet
        self.tileId = tileId
    }
    
    init() {
        self.texture = nil
        self.subRect = nil
        tileSet = nil
        tileId = -1
    }
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
    
    /// The references to the animation data for each tile
    public var animations   : [Int: MMTile] = [:]
    
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
                
                // Parse the object's groups and animations and store them for easier access
                for object in tileSetData.tileObjects {
                    objects[object.id] = object.objectGroup
                                                            
                    if object.animation.isEmpty == false {
                        
                        let animTile = MMTile()
                        var animData : [MMTile] = []
                        
                        for a in object.animation {
                            let t = getTile(id: a.tileid)
                            print("11", t.texture, a.tileid)
                            animData.append(t)
                        }
                        
                        animTile.animation = animData
                        animations[object.id] = animTile
                    }
                }
            }
            
            return tileSetData
        }
        return nil
    }
    
    public func getAnimation(id: Int) -> MMTile? {
        return animations[id]
    }
    
    /// Return the tile at the given grid id
    public func getTile(id: Int) -> MMTile {
        
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
