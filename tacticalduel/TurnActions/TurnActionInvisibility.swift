//
//  TurnActionInvisibility.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 17/11/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

class TurnActionInvisibility: TurnAction {
    private let object: Invisible
    
    let iconName = "power2"
    let turnSlots = GameBalance.shared.invisibilitySlots
    
    init(object: Invisible) {
        self.object = object
    }
    
    func doAction() {
        object.hide(turnsNumber: GameBalance.shared.invisibilityTurnsNumber)
    }
}
