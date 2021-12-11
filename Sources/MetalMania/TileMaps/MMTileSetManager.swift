//
//  File.swift
//  
//
//  Created by Markus Moenig on 7/12/21.
//

import Foundation

public class MMTileSetManager {
    
    let mmView              : MMView
    
    var tileSets            : [String: MMTileSet] = [:]

    init(_ mmView: MMView) {
        self.mmView = mmView
    }
    
    /// Adds a tileset of the given file name
    @discardableResult public func addTileSet(byFileName: String, load: Bool = false) -> MMTileSet? {
        if tileSets[byFileName] == nil {
            let tileSet = MMTileSet(mmView, fileName: byFileName)
            if load {
                tileSet.load()
            }
            tileSets[byFileName] = tileSet
            return tileSet
        }
        return nil
    }
    
    /// Returns the tile of the given id from the given tileSet
    func getTile(tileSetName: String, id: Int) -> MMTile? {
        if let tileSet = tileSets[tileSetName] {
            return tileSet.getTile(id: id)
        }
        return nil
    }
}
