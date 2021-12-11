//
//  MMTileMap.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

open class MMTileMap : MMWidget {
    
    static public var tileSetManager : MMTileSetManager! = nil
    
    var fileName                : String
    
    public var tileMapData      : MMTileMapData! = nil
    
    public var layers           : [MMTileMapLayer] = []
    public var tiles            : [Int: MMTile] = [:]
    
    public var actors           : [MMActor] = []
    
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
    
    /// Loads all dependencies like tilesets, tiles and initializes physics
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
                                    tile.box2DBody = setupTilePhysics(x: x, y: y, object: o)
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
    
    /// Setup the physics for one tile
    func setupTilePhysics(x: Float, y: Float, object: MMTileObjectData, type: b2BodyType = .staticBody) -> b2Body? {
        
        let bodyDef = b2BodyDef()
        
        //bodyDef.angle = 0
        bodyDef.type = type
                
        let fixtureDef = b2FixtureDef()
        fixtureDef.shape = nil

        //fixtureDef.filter.categoryBits = categoryBits
        //fixtureDef.filter.maskBits = 0xffff
        
        let polyShape = b2PolygonShape()
        polyShape.setAsBox(halfWidth: object.width / 2.0 / ppm - polyShape.m_radius, halfHeight: object.height / 2.0 / ppm - polyShape.m_radius)
        fixtureDef.shape = polyShape
        
        fixtureDef.friction = 0.1
        if type == .staticBody {
            fixtureDef.density = 0
        } else {
            fixtureDef.density = 0.1
        }
        fixtureDef.restitution = 0
        
        let aspect = float2(1,1)
        
        bodyDef.position.set((x / aspect.x) / ppm, (y / aspect.y) / ppm)
        
        let body = box2DWorld.createBody(bodyDef)
        body.createFixture(fixtureDef)
        
        return body
    }
    
    /// Creates a new actor
    public func createActor(name: String) -> MMActor {
        
        let actor = MMActor(tileMap: self)
        
        if let object = getObject(ofName: name) {
            actor.setObjectData(objectData: object)
        }
        
        actors.append(actor)
        
        return actor
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

        let timeStep: b2Float = 1.0 / 60.0
        let velocityIterations = 6
        let positionIterations = 2
    
        box2DWorld.step(timeStep: timeStep, velocityIterations: velocityIterations, positionIterations: positionIterations)
        
        for layer in layers {
            
            if layer.layerData.type == .tile && layer.layerData.visible == true {
                
                var x : Float = offsetX * zoom + Float(layer.layerData.x) * zoom
                var y : Float = offsetY * zoom + Float(layer.layerData.y) * zoom
                
                var rowCounter = 0

                for t in layer.layerData.data {
                    if t > 0 {
                        
                        if let tile = tiles[t] {
                            drawTile(x: x, y: y, tile: tile)
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
        
        for a in actors {
            a.draw()
        }
    }
    
    func drawTile(x: Float, y: Float, tile: MMTile) {
        if let animation = tile.animation, animation.isEmpty == false {
            let first = animation.first
            if let texture = first?.texture {
                mmView.drawTexture.draw(texture, x: x, y: y, zoom: 1/zoom, subRect: first!.subRect)
            }
        } else {
            if let texture = tile.texture {
                mmView.drawTexture.draw(texture, x: x, y: y, zoom: 1/zoom, subRect: tile.subRect)
            }
        }
    }
}
