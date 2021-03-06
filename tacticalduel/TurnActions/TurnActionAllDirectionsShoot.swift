//
//  ActionAllDirectionsShoot.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 05/11/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

class ActionAllDirectionsShoot: Action {
    private let source: () -> HxCoordinates
    private let map: HxMap
    
    let iconName = "power2"
    let turnSlots = GameBalance.shared.allDirectionsShootSlots
    
    var targetArea: [HxCoordinates] {
        var area = [HxCoordinates]()
        for direction in HxDirection.allCases {
            area.append(contentsOf: map.straightPath(from: source(), to: direction))
        }
        return area
    }
    
    init(source: @escaping () -> HxCoordinates, on map: HxMap) {
        self.source = source
        self.map = map
    }
    
    func damage(at coordinates: HxCoordinates) -> Int {
        if targetArea.contains(coordinates) {
            return GameBalance.shared.allDirectionsDamage
        } else {
            return 0
        }
    }
    
    func doAction() {
        for cell in targetArea {
            guard let objects = map.cell(at: cell)?.mapObjects else { continue }
            
            for object in objects {
                if let mortal = object as? Mortal {
                    mortal.apply(damage: damage(at: cell))
                }
            }
        }
    }
}
