//
//  MMTileMap.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

open class MMTileMap : MMWidget {
    
    static var tileSetManager   : MMTileSetManager? = nil
    
    var fileName                : String
    
    var tileMapData             : MMTileMapData! = nil
    
    var layers                  : [MMTileMapLayer] = []
    
    public init(_ mmView: MMView, fileName: String) {
        self.fileName = fileName
        super.init(mmView)
        
        if MMTileMap.tileSetManager == nil {
            MMTileMap.tileSetManager = MMTileSetManager(mmView)
        }
    }
    
    public func load() -> MMTileMapData? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = NSData(contentsOfFile: path)! as Data
            
            tileMapData = try? JSONDecoder().decode(MMTileMapData.self, from: data)

            return tileMapData
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
    
    /// Initializes the layers from the loaded layer data
    func initLayers() {
        layers = []
        for tileSetDataRef in tileMapData.tilesets {
        }
    }
}
