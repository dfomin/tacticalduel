//
//  HxGameScene.swift
//  tacticalduel
//
//  Created by Dmitry Fomin on 07/05/2018.
//  Copyright © 2018 Dmitry Fomin. All rights reserved.
//

import SpriteKit
import GameplayKit

class HxGameScene: SKScene {
    var edge: CGFloat!
    var mapView: HxMapView!
    var gameOver = false {
        didSet {
            if gameOver {
                log.commit()
                UserDefaults.standard.set(log.log, forKey: log.name)
            }
        }
    }
    let log = GameLog()
    var currentTeam = "" {
        didSet {
            for r in -mapView.map.radius ... mapView.map.radius {
                for q in -mapView.map.radius ... mapView.map.radius {
                    let coordinates = HxCoordinates(q, r)
                    if let cell = mapView.map.cell(at: coordinates) {
                        for object in cell.mapObjects {
                            if object is FireTrap {
                                mapView.set(color: object.team == currentTeam ? .orange : .clear, for: coordinates)
                            }
                        }
                    }
                }
            }
            
            for character in characters {
                character.node.isHidden = currentTeam != character.character.team ? character.character.isHidden : false
            }
        }
    }
    var characters = [CharacterView]()
    
    var buttons = [SKSpriteNode]()
    var turns = [String: CharacterTurn]()
    var selectedCharacter: Character? {
        didSet {
            updateActions()
            
            if let oldCoordinates = oldValue?.coordinates {
                mapView.set(color: .clear, for: oldCoordinates)
            }
            
            if let coordinates = selectedCharacter?.coordinates {
                mapView.set(color: .red, for: coordinates)
            }
        }
    }
    
    var currentAction: TurnActionTarget? {
        didSet {
            if let coordinates = currentAction?.target {
                mapView.set(color: .yellow, for: coordinates)
            } else {
                if let oldCoordinates = oldValue?.target {
                    if oldCoordinates != selectedCharacter?.coordinates {
                        mapView.set(color: .clear, for: oldCoordinates)
                        
                        let team = currentTeam
                        currentTeam = team
                    } else {
                        mapView.set(color: .red, for: oldCoordinates)
                    }
                }
            }
        }
    }
    
    let actionsNode = SKNode()
    var processButton: SKSpriteNode!
    var logButton: SKSpriteNode!

    override func sceneDidLoad() {
        let radius = 3
        edge = frame.width / CGFloat((2 * radius + 1) + (radius + 1))
        mapView = HxMapView(radius: radius, edge: edge, center: CGPoint(x: frame.width / 2, y: frame.height / 2))
        addChild(mapView.node)
        
        let freeSpace = (frame.height - edge * CGFloat(2 * radius + 1) * CGFloat(sqrt(3.0))) / CGFloat(2.0)
        
        self.backgroundColor = .gray
        
        let buttonNames = [
            "move2",
            "move4",
            "move6",
            "move8",
            "move10",
            "move12",
            "shoot",
            "power1",
            "power2",
            "skip"
        ]
        
        for (i, name) in buttonNames.enumerated() {
            let button = SKSpriteNode(imageNamed: name)
            button.anchorPoint = CGPoint(x: 0, y: 1)
            button.size = CGSize(width: freeSpace / 2, height: freeSpace / 2)
            button.position = CGPoint(x: CGFloat(i % 5) * frame.width / CGFloat(buttonNames.count / 2),
                                      y: frame.height - button.frame.height * CGFloat(i / 5))
            buttons.append(button)
            addChild(button)
        }
        
        actionsNode.position = CGPoint(x: frame.width / 2, y: 0)
        addChild(actionsNode)
        
        processButton = SKSpriteNode(color: .yellow, size: CGSize(width: freeSpace / 2, height: freeSpace / 2))
        processButton.anchorPoint = CGPoint(x: 0, y: 0)
        processButton.position = CGPoint(x: 0, y: 0)
        addChild(processButton)
        
        logButton = SKSpriteNode(color: .white, size: CGSize(width: freeSpace / 2, height: freeSpace / 2))
        logButton.anchorPoint = CGPoint(x: 1, y: 0)
        logButton.position = CGPoint(x: frame.width, y: 0)
        addChild(logButton)
        
        currentTeam = "team 1"
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            (self.view?.window?.rootViewController as! UINavigationController).popViewController(animated: true)
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        let point = viewToMap(point: location)
        let coordinates = mapView.coordinates(at: point)
        if mapView.map.isInside(coordinates: coordinates) {
            if var targetAction = currentAction {
                if selectedCharacter?.coordinates != targetAction.target {
                    mapView.set(color: .clear, for: targetAction.target)
                } else {
                    mapView.set(color: .red, for: targetAction.target)
                }
                targetAction.target = coordinates
                mapView.set(color: .yellow, for: coordinates)
            } else if let characterAtCell = mapView.map.cell(at: coordinates)?.mapObjects.first as? Character, characterAtCell.team == currentTeam {
                selectedCharacter = characterAtCell
            } else {
                selectedCharacter = nil
            }
        } else if let character = selectedCharacter {
            var buttonTapped = false
            for button in buttons {
                if button.contains(location) {
                    if let index = buttons.index(of: button) {
                        let action = createAction(index: index)
                        if turns[character.name]!.hasSpaceFor(slots: action.turnSlots) {
                            turns[character.name]!.append(action: action)
                            updateActions()
                        } else {
                            currentAction = nil
                        }
                        
                        buttonTapped = true
                    }
                }
            }
            
            for (i, actionSprite) in actionsNode.children.enumerated() {
                if actionSprite.contains(touch.location(in: actionsNode)) {
                    turns[character.name]!.remove(at: i)
                    updateActions()
                    
                    buttonTapped = true
                }
            }
            
            if !buttonTapped {
                selectedCharacter = nil
                currentAction = nil
            }
        }
        
        if processButton.contains(location) {
            selectedCharacter = nil
            currentAction = nil
            
            if currentTeam == "team 1" {
                currentTeam = ""
                processButton.color = .white
            } else if currentTeam == "" {
                currentTeam = "team 2"
                processButton.color = .blue
            } else if currentTeam == "team 2" {
                currentTeam = "end"
                processButton.color = .white
                processActions(i: 0)
            } else if currentTeam == "end" {
                log.commit()
                currentTeam = "team 1"
                processButton.color = .yellow
            }
        }
        
        if logButton.contains(location) {
            selectedCharacter = nil
            currentAction = nil
            
            let alert = UIAlertController(title: "", message: log.lastTurn, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func createTeam(name: String, heroes: [String], positions: [(Int, Int)]) {
        for (i, hero) in heroes.enumerated() {
            let hero = create(name: hero, q: positions[i].0, r: positions[i].1, edge: edge, team: name)
            characters.append(hero)
            
            turns[hero.name] = CharacterTurn(numberOfActions: GameBalance.shared.turnsNumber)
        }
        
        log.add(team: name, heroes: zip(heroes, positions).map { "\($0)(\($1.0),\($1.1))" })
    }
    
    private func create(name: String, q: Int, r: Int, edge: CGFloat, team: String) -> CharacterView {
        let coordinates = HxCoordinates(q: q, r: r)
        let character = CharacterView(coordinates: coordinates, name: name, team: team, edge: edge)
        mapView.map.add(object: character.character, at: coordinates)
        mapView.add(objectView: character.node, for: character.name)
        return character
    }
    
    private func createAction(index: Int) -> TurnAction {
        currentAction = nil
        
        switch index {
        case 0:
            return TurnActionMove(direction: .oclock2, object: selectedCharacter!, on: mapView.map)
        case 1:
            return TurnActionMove(direction: .oclock4, object: selectedCharacter!, on: mapView.map)
        case 2:
            return TurnActionMove(direction: .oclock6, object: selectedCharacter!, on: mapView.map)
        case 3:
            return TurnActionMove(direction: .oclock8, object: selectedCharacter!, on: mapView.map)
        case 4:
            return TurnActionMove(direction: .oclock10, object: selectedCharacter!, on: mapView.map)
        case 5:
            return TurnActionMove(direction: .oclock12, object: selectedCharacter!, on: mapView.map)
        case 6:
            let action = TurnActionCommonShoot(target: HxCoordinates(q: 0, r: 0), on: mapView.map)
            currentAction = action
            return action
        case 7:
            let action = power(number: 1, for: selectedCharacter!)
            if let targetAction = action as? TurnActionTarget {
                currentAction = targetAction
            }
            return action
        case 8:
            let action = power(number: 2, for: selectedCharacter!)
            if let targetAction = action as? TurnActionTarget {
                currentAction = targetAction
            }
            return action
        case 9:
            return TurnActionSkip()
        default:
            assert(false)
            return TurnActionSkip()
        }
    }
    
    private func power(number: Int, for character: Character) -> TurnAction {
        if character.name == "night" {
            if number == 1 {
                return TurnActionPoison(target: HxCoordinates(0, 0), team: character.team, on: mapView.map)
            } else if number == 2 {
                return TurnActionInvisibility(object: character)
            }
        } else if character.name == "fire" {
            if number == 1 {
                return TurnActionFireSection(source: { character.coordinates }, target: HxCoordinates(0, 0), on: mapView.map)
            } else if number == 2 {
                return TurnActionFireTrap(team: character.team, on: mapView.map)
            }
        } else if character.name == "water" {
            if number == 1 {
                return TurnActionOneDirectionShoot(source: { character.coordinates }, target: HxCoordinates(0, 0), on: mapView.map)
            } else if number == 2 {
                return TurnActionFreeze(target: HxCoordinates(0, 0), on: mapView.map)
            }
        } else if character.name == "stone" {
            if number == 1 {
                return TurnActionThrowStone(target: HxCoordinates(0, 0), on: mapView.map)
            } else if number == 2 {
                return TurnActionAllDirectionsShoot(source: { character.coordinates }, on: mapView.map)
            }
        } else if character.name == "ent" {
            if number == 1 {
                return TurnActionSplashShoot(target: HxCoordinates(0, 0), on: mapView.map)
            } else if number == 2 {
                return TurnActionHeal(object: character)
            }
        } else if character.name == "weather" {
            if number == 1 {
                return TurnActionLightning(target: HxCoordinates(0, 0), on: mapView.map)
            } else if number == 2 {
                return TurnActionBlow(target: HxCoordinates(0, 0), on: mapView.map)
            }
        }
        
        return TurnActionSkip()
    }
    
    private func updateActions() {
        actionsNode.removeAllChildren()
        
        if let name = selectedCharacter?.name, let turn = turns[name] {
            for (i, action) in turn.actions.enumerated() {
                let sprite = SKSpriteNode(imageNamed: action?.iconName ?? "empty")
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
                sprite.position = CGPoint(x: CGFloat(i - 1) * sprite.frame.width * 1.5, y: sprite.frame.height / 2)
                actionsNode.addChild(sprite)
            }
        }
    }
    
    private func processActions(i: Int) {
        guard i < GameBalance.shared.turnsNumber else {
            for character in characters {
                turns[character.name] = CharacterTurn(numberOfActions: GameBalance.shared.turnsNumber)
            }
            
            updateActions()
            
            return
        }
        
        var names = characters.map { $0.name }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let fireTrapAction = actions[i] as? TurnActionFireTrap {
                fireTrapAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let healAction = actions[i] as? TurnActionHeal {
                healAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let moveAction = actions[i] as? TurnActionMove {
                moveAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let blowAction = actions[i] as? TurnActionBlow {
                blowAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let poisonAction = actions[i] as? TurnActionPoison {
                poisonAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for r in -mapView.map.radius ... mapView.map.radius {
            for q in -mapView.map.radius ... mapView.map.radius {
                let coordinates = HxCoordinates(q, r)
                if let cell = mapView.map.cell(at: coordinates) {
                    if !cell.mapObjects.filter({ $0 is Mortal }).isEmpty {
                        for object in cell.mapObjects {
                            if let activatable = object as? Activatable {
                                log.add(event: object.name)
                                activatable.activate()
                            }
                        }
                    }
                }
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let shootAction = actions[i] as? TurnActionAllDirectionsShoot {
                shootAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let shootAction = actions[i] as? TurnActionDamage {
                shootAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let freezeAction = actions[i] as? TurnActionFreeze {
                freezeAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for (name, actions) in turns {
            guard let character = characters.first(where: { $0.character.name == name })?.character, character.canAct else {
                continue
            }
            
            if let invisibilityAction = actions[i] as? TurnActionInvisibility {
                invisibilityAction.doAction()
                log.add(hero: name, action: actions[i]!)
                
                names.removeAll(where: { $0 == name })
            }
        }
        
        for character in characters {
            if names.contains(character.name) {
                mapView.wait(objectView: character)
            }
        }
        
        for r in -mapView.map.radius ... mapView.map.radius {
            for q in -mapView.map.radius ... mapView.map.radius {
                let coordinates = HxCoordinates(q, r)
                if let cell = mapView.map.cell(at: coordinates) {
                    for object in cell.mapObjects {
                        if let temporary = object as? Temporary {
                            temporary.turnIsOver()
                        }
                    }
                }
            }
        }
        
        for character in characters {
            character.node.isHidden = character.character.isHidden
        }
        
        for character in characters {
            if character.character.health <= 0 {
                mapView.map.remove(object: character.character, at: character.character.coordinates)
            }
        }
        
        let aliveHeroes1 = characters.filter { $0.character.team == "team 1" && !$0.character.isDead }.count
        let aliveHeroes2 = characters.filter { $0.character.team == "team 2" && !$0.character.isDead }.count
        if aliveHeroes1 == 0 || aliveHeroes2 == 0 {
            let text = aliveHeroes1 > 0 ? "Player 1" : aliveHeroes2 > 0 ? "Player 2" : "Draw"
            let label = SKLabelNode(text: text)
            label.fontColor = .green
            label.fontName = "AvenirNext-Bold"
            label.position = CGPoint(x: self.frame.width / 2, y: 0)
            addChild(label)
            
            gameOver = true
        }
        
        mapView.runActions(callback: { self.processActions(i: i + 1) })
    }
    
    private func mapToView(point: CGPoint) -> CGPoint {
        var viewPoint = self.convert(point, from: mapView.node)
        viewPoint.y = frame.height - viewPoint.y
        return viewPoint
    }
    
    private func viewToMap(point: CGPoint) -> CGPoint {
        var point = point
        point.y = frame.height - point.y
        return self.convert(point, to: mapView.node)
    }
}