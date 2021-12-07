//
//  MMTileSet.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import MetalKit

open class MMTileSet {
    
    let mmView              : MMView
    
    var fileName            : String
    
    public var texture      : MTLTexture? = nil
    public var tileSetData  : MMTileSetData! = nil
    
    public init(_ mmView: MMView, fileName: String) {
        self.mmView = mmView
        self.fileName = fileName
    }
    
    public func load() -> MMTileSetData? {
        
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
}
