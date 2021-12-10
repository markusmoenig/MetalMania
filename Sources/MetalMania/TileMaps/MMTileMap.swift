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
    
    // Physics related
    
    /// The Box2D world for this map
    var box2DWorld              : b2World

    /// Set automatically to the tile height of the map, you can set it to a custom value before called load().
    var ppm                     : Float = 0
    
    public init(_ mmView: MMView, fileName: String) {
        
        self.fileName = fileName
        
        box2DWorld = b2World(gravity: b2Vec2(0, 10))
        
        super.init(mmView)
                
        if MMTileMap.tileSetManager == nil {
            MMTileMap.tileSetManager = MMTileSetManager(mmView)
        }
    }
    
    @discardableResult public func load() -> MMTileMapData? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            let data = NSData(contentsOfFile: path)! as Data
            
            tileMapData = try? JSONDecoder().decode(MMTileMapData.self, from: data)
            
            if ppm == 0 {
                ppm = Float(tileMapData.tileHeight)
            }

            initLayersAndTiles()
            initPhysics()
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
    
    /// Init physiycs
    func initPhysics() {
        
        func setupTilePhysics(x: Float, y: Float, tile: MMTile, object: MMTileObjectData) {
            print(x, y, tile.tileId, object.y)
            
            var bodyDef = b2BodyDef()
        }
        
        // Parse all tiles and set up physics for them
        for layer in layers {
            
            if layer.layerData.type == .tile && layer.layerData.visible == true {
                
                var x : Float = offsetX * zoom + Float(layer.layerData.x) * zoom
                var y : Float = offsetY * zoom + Float(layer.layerData.y) * zoom
                
                var rowCounter = 0

                for t in layer.layerData.data {
                    if t > 0 {
                        
                        if let tile = tiles[t] {
                            if let objectGroup = tile.tileSet?.objects[tile.tileId] {
                                for o in objectGroup.objects {
                                    setupTilePhysics(x: x, y: y, tile: tile, object: o)
                                }
                            }
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
