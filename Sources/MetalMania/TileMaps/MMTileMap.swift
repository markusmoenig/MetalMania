//
//  MMTileMap.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

open class MMTileMap : MMWidget {
    
    static var tileSetManager   : MMTileSetManager! = nil
    
    var fileName                : String
    
    var tileMapData             : MMTileMapData! = nil
    
    var layers                  : [MMTileMapLayer] = []
    var tiles                   : [Int: MMTile] = [:]
    
    public var offsetX          : Float = 0
    public var offsetY          : Float = 0

    public init(_ mmView: MMView, fileName: String) {
        self.fileName = fileName
        super.init(mmView)
        
        if MMTileMap.tileSetManager == nil {
            MMTileMap.tileSetManager = MMTileSetManager(mmView)
        }
    }
    
    @discardableResult public func load() -> MMTileMapData? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = NSData(contentsOfFile: path)! as Data
            
            tileMapData = try? JSONDecoder().decode(MMTileMapData.self, from: data)

            initLayersAndTiles()
            return tileMapData
        }
        return nil
    }
    
    /// Initializes the layers from the loaded layer data
    func initLayersAndTiles() {
        tiles = [:]
        
        // Add the tile sets to the manager
        for tileSetDataRef in tileMapData.tilesets {
            MMTileMap.tileSetManager.addTileSet(byFileName: tileSetDataRef.source)
        }
    
        // Add the layer classes based on the data classes
        for layerData in tileMapData.layers {
            let layer = MMTileMapLayer(mmView, tileMap: self, layerData: layerData)
            layers.append(layer)
        }
        
        /// Returns the name of the tileset for the given tile gid
        func getTileRefForId(_ id: Int) -> MMTileSetRefData? {
            
            var startgid        : Int = -1
            var tileRef         : MMTileSetRefData? = nil
            
            for tileSetDataRef in tileMapData.tilesets {

                if tileSetDataRef.firstgid <= id && tileSetDataRef.firstgid > startgid {
                    startgid = tileSetDataRef.firstgid
                    tileRef = tileSetDataRef
                }
            }
            
            return tileRef
        }
        
        // Now create ALL the tile structs for the whole map
        
        for layer in layers {
            for t in layer.layerData.data {
                if t > 0 {
                    if tiles[t] == nil {
                        if let tileRef = getTileRefForId(t) {
                            tiles[t] = MMTileMap.tileSetManager.getTile(tileSetName: tileRef.source, id: t - tileRef.firstgid)
                        }
                    }                    
                }
            }
        }
    }
    
    /// Returns the obect data for the given objectName
    public func getObject(ofName: String) -> MMTileObjectData? {
        for layer in layers {
            
            if layer.layerData.type == .objectGroup {
                for o in layer.layerData.objects {
                    if o.name == ofName {
                        return o
                    }
                }
            }
        }
        return nil
    }
    
    /// Draws the layers
    open override func draw(xOffset: Float = 0, yOffset: Float = 0) {

        for layer in layers {
            
            if layer.layerData.type == .tile && layer.layerData.visible == true {
                
                var x : Float = offsetX * zoom + Float(layer.layerData.x) * zoom
                var y : Float = offsetY * zoom + Float(layer.layerData.y) * zoom
                
                var rowCounter = 0

                for t in layer.layerData.data {
                    if t > 0 {
                        
                        if let tile = tiles[t] {
                            mmView.drawTexture.draw(tile.texture!, x: x, y: y, zoom: 1/zoom, subRect: tile.subRect)
                        }
                    }
                    
                    rowCounter += 1
                    
                    x += Float(tileMapData.tileWidth) * zoom
                    if rowCounter == tileMapData.width {
                        x = offsetX * zoom
                        rowCounter = 0
                        y += Float(tileMapData.tileHeight) * zoom
                    }
                }
            }
        }
    }
}
