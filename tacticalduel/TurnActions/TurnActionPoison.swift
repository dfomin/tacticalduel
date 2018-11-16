//
//  TurnActionPoison.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 16/11/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

class TurnActionPoison: TurnActionTarget {
    private let map: HxMap
    
    var target: HxCoordinates
    
    var targetArea: [HxCoordinates] {
        var area = [target]
        area.append(contentsOf: map.neighbors(of: target))
        return area
    }
    
    var iconName: String {
        return "power2"
    }
    
    init(target: HxCoordinates, on map: HxMap) {
        self.target = target
        self.map = map
    }
    
    func doAction() {
        for coordinates in targetArea {
            let poisonCell = Poison(coordinates: coordinates, on: map)
            map.add(object: poisonCell, at: coordinates)
        }
    }
}
