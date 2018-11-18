//
//  TurnActionSkip.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 22/10/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

class TurnActionSkip: TurnAction {
    let iconName = "skip"
    let turnSlots = GameBalance.shared.skipSlots
    
    func doAction() {}
}
