//
//  MMTileSet.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import MetalKit

public struct MMTile {
    var texture             : MTLTexture? = nil
    var subRect             : MMRect? = nil
}

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
    
    func getTile(id: Int) -> MMTile {
        
        var tileTexture : MTLTexture? = nil
        var tileSubRect : MMRect? = nil
        
        tileTexture = texture
        tileSubRect = MMRect(0, 0, Float(tileSetData.tileWidth), Float(tileSetData.tileHeight))
        
        return MMTile(texture: tileTexture, subRect: tileSubRect)
    }
}
