//
//  MMActor.swift
//  
//
//  Created by Markus Moenig on 11/12/21.
//

import Foundation

open class MMActor {
    
    let tileMap                 : MMTileMap
    
    public var objectData       : MMTileObjectData? = nil
    
    public var x                : Float = 0
    public var y                : Float = 0
    
    var tiles                   : [String: MMTile] = [:]
    var currentTile             : MMTile? = nil
    var defaultTile             : MMTile? = nil

    public var body             : b2Body? = nil

    init(tileMap: MMTileMap) {
        self.tileMap = tileMap
    }
    
    func setObjectData(objectData: MMTileObjectData) {
        self.objectData = objectData
        
        x = objectData.x
        y = objectData.y
        
        body = tileMap.setupTilePhysics(x: x, y: y, object: objectData, type: .dynamicBody)
    }
    
    /// Adds a named tile for the actor and optionally makes it the default tile
    public func addNamedTile(name: String, tile: MMTile, makeDefault: Bool = false) {
        tiles[name] = tile
        if makeDefault {
            currentTile = tile
            defaultTile = tile
        }
    }
    
    open func draw() {
        
        if let body = body {
            x = body.position.x * tileMap.ppm
            y = body.position.y * tileMap.ppm
        }
        
        let zoom = tileMap.zoom
        
        let x : Float = tileMap.offsetX * zoom + self.x * zoom
        let y : Float = tileMap.offsetY * zoom + self.y * zoom
        
        if let currTile = currentTile {
            //print(currTile.texture, currTile.animation)
            tileMap.drawTile(x: x, y: y, tile: currTile)
            //tileMap.mmView.drawBox.draw( x: x, y: y, width: objectData!.width * zoom, height: objectData!.height * zoom, round: 10, borderSize: 2, fillColor: float4(1,0,0,1), borderColor: float4(1,1,1,1))
        }
    }
}
