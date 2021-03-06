//
//  Freezable.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 17/11/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

protocol Freezable: Temporary {
    var isFreezed: Bool { get }
    func freeze(turnsNumber: Int)
}
