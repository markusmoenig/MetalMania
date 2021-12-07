//
//  MMTileMap.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

open class MMTileMap {
    
    let mmView          : MMView
    
    var fileName        : String
    
    //var texture         : MTLTexture? = nil
    var tileMapData     : MMTileMapData! = nil
    
    public init(_ mmView: MMView, fileName: String) {
        self.mmView = mmView
        self.fileName = fileName
    }
    
    public func load() -> MMTileMapData? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = NSData(contentsOfFile: path)! as Data
            
            tileMapData = try? JSONDecoder().decode(MMTileMapData.self, from: data)

            /*
            if let tileSetData = tileSetData {
                
                if tileSetData.imageName.isEmpty == false {
                 
                    let array = tileSetData.imageName.split(separator: ".")
                    if array.count == 2 {
                        texture = mmView.loadTexture(String(array[0]), type: String(array[1]))
                    }
                }
            }
            
            return tileSetData
            print("data", tileSetData)
             */
        }
        return nil
    }
}
