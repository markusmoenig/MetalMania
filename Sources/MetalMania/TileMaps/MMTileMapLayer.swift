//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

class MMTileMapLayer {
 
    let mmView              : MMView
    
    let tileMap             : MMTileMap
    let layerData           : MMTileMapLayerData

    public init(_ mmView: MMView, tileMap: MMTileMap, layerData: MMTileMapLayerData) {
        self.mmView = mmView
        self.tileMap = tileMap
        self.layerData = layerData
    }
}
