//
//  Parser.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 28/11/22.
//

import Foundation

struct SystemTracker {
    private (set) var movingMassState = subSystemActionState.MovingMassState.stop
    private (set) var levellingState = subSystemActionState.LevellingState.stop
    private (set) var gyroState = subSystemActionState.GyroState.stop
    private (set) var releaseStopCommand: Command.controlCommand? //for manual control
    private (set) var autoIfStopCommand: Command.controlCommand?
    private (set) var nextCommandToSend: Command.controlCommand?
    
    //TODO: what to process for each of the command
    //1. check current action state, if its the same, ignore (any use case requires resending the same cmd?
    //2. check availablity, status: ready, busy, stop
    //3. accept new command and update the action state (update status as well? or wait for the message?)
    //...
    
    mutating func processUserInput(of command: Command.controlCommand) -> String? {
        switch command {
        case .XPlusManual, .XMinusManual:
            if checkMassSystemState(of: .moveX) {
                movingMassState = .moveX
                releaseStopCommand = Command.controlCommand.XStop
            } else {
                return nil
            }
        case .YMinusManual, .YPlusManual:
            if checkMassSystemState(of: .moveY) {
                movingMassState = .moveY
                releaseStopCommand = Command.controlCommand.YStop
            } else {
                return nil
            }
        case .YStop, .XStop:
            movingMassState = .stop
        case .upManual:
            if checkLevelSystemState(of: .up) {
                levellingState = .up
                releaseStopCommand = Command.controlCommand.levelStop
            } else {
                return nil
            }
        case .downManual:
            if checkLevelSystemState(of: .up) {
                levellingState = .down
                releaseStopCommand = Command.controlCommand.levelStop
            } else {
                return nil
            }
        case .keepLevelOn:
            levellingState = .levelOnce
        case .levelStop:
            levellingState = .stop
        case .autoGyroOn:
            gyroState = .autoOn
        case .autoGyroOff:
            gyroState = .autoOff
        case .upAuto:
            autoIfStopCommand = .levelStop
            levellingState = .up
        case .downAuto:
            autoIfStopCommand = .levelStop
            levellingState = .down
        case .YAutoSet:
            nextCommandToSend = .autoMove
            autoIfStopCommand = .massStop
            movingMassState = .moveY
        case .XAutoSet:
            nextCommandToSend = .autoMove
            autoIfStopCommand = .massStop
            movingMassState = .moveX
        case .adjustAngleAuto:
            autoIfStopCommand = .adjustStopAuto
            gyroState = .adjustAngle
        default:
            return nil
        }
        return command.rawValue
    }
    
    private func checkMassSystemState(of newState: subSystemActionState.MovingMassState) -> Bool {
        return newState != movingMassState
    }
    
    private func checkLevelSystemState(of newState: subSystemActionState.LevellingState) -> Bool {
        return newState != levellingState
    }
    
    mutating func clearReleaseStopAfterSending(){
        releaseStopCommand = nil
    }
    
    mutating func clearAutoStopAfterSending(){
        autoIfStopCommand = nil
    }
    
    
}

struct subSystemActionState {
    enum MovingMassState {
        case moveX
        case moveY
        case stop
    }
    
    enum LevellingState {
        case levelOnce
        case keepLevel
        case up
        case down
        case stop
    }
    
    enum GyroState {
        case autoOn
        case autoOff
        case adjustAngle
        case stop
    }
}

struct SystemStatus {
    enum SubsystemStatus: String {
        case wait = "wait"
        case ready = "ready"
        case busy = "busy"
        case error = "warning"
        case lock = "lock"
    }
}
