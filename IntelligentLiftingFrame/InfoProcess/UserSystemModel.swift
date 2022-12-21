//
//  Parser.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 28/11/22.
//

import Foundation

struct SystemTracker {
    //action state
    private (set) var movingMassState = SubSystemState.MovingMassState.stop
    private (set) var levellingState = SubSystemState.LevellingState.stop
    private (set) var gyroState = SubSystemState.GyroState.stop
    //status
    private (set) var movingMassStatus: SystemConstants.SubsystemStatus?
    private (set) var levellingStatus: SystemConstants.SubsystemStatus?
    private (set) var gyroStatus: SystemConstants.SubsystemStatus?
    //command related
    private (set) var releaseStopCommand: Command.controlCommand? //for manual control
    private (set) var autoIfStopCommand: Command.controlCommand?
    private (set) var nextCommandToSend: Command.controlCommand?
    
    //TODO: what to process for each of the command
    //1. check current action state, if its the same, ignore (any use case requires resending the same cmd?
    //2. check availablity, status: ready, busy, stop
    //3. accept new command and update the action state (update status as well? or wait for the message?)
    //...
    
    mutating func processUserInput(of command: Command.controlCommand) -> String? {
        var toSendCmd = false
        
        switch command {
        case .XPlusManual, .XMinusManual:
            toSendCmd = processMassMoveManual(of: .moveX)
        case .YMinusManual, .YPlusManual:
            toSendCmd = processMassMoveManual(of: .moveY)
        case .YStop, .XStop:
            movingMassState = .stop
        case .upManual:
            toSendCmd = processLevelMoveManual(of: .up)
        case .downManual:
            toSendCmd = processLevelMoveManual(of: .down)
        case .keepLevelOn:
            levellingState = .keepLevel
            toSendCmd = true
        case .levelStop:
            levellingState = .stop
            toSendCmd = true
        case .autoGyroOn:
            gyroState = .autoOn
            toSendCmd = true
        case .autoGyroOff:
            gyroState = .autoOff
            toSendCmd = true
        case .upAuto:
            toSendCmd = processLevelMoveAuto(of: .up)
        case .downAuto:
            toSendCmd = processLevelMoveAuto(of: .down)
        case .YAutoSet:
            toSendCmd = processMassSet(of: .moveY)
        case .XAutoSet:
            toSendCmd = processMassSet(of: .moveX)
        case .adjustAngleAuto:
            autoIfStopCommand = .adjustStopAuto
            gyroState = .autoOn
            toSendCmd = true
        default:
            return nil
        }
        if toSendCmd {
            return command.rawValue
        } else {
            return nil
        }
    }
    
    mutating func clearReleaseStopAfterSending(){
        releaseStopCommand = nil
    }
    
    mutating func clearAutoStopAfterSending(){
        autoIfStopCommand = nil
    }
    
    mutating func clearNextCommand() {
        nextCommandToSend = nil
    }
    
    mutating func processMassMoveManual(of newState: SubSystemState.MovingMassState) -> Bool {
        if newState != movingMassState {
            movingMassState = newState
            if newState == .moveX {
                releaseStopCommand = Command.controlCommand.XStop
            } else {
                releaseStopCommand = Command.controlCommand.YStop
            }
            return true
        } 
        return false
    }
    
    mutating func processLevelMoveManual(of newState: SubSystemState.LevellingState) -> Bool {
        if levellingState != .keepLevel {
            if levellingState != newState {
                levellingState = newState
                releaseStopCommand = Command.controlCommand.levelStop
                return true
            }
        }
        return false
    }
    
    mutating func processLevelMoveAuto(of newState: SubSystemState.LevellingState) -> Bool {
        if levellingState != .keepLevel {
            levellingState = newState
            autoIfStopCommand = Command.controlCommand.levelStop
            return true
        } else {
            return false
        }
    }
    
    mutating func processMassSet(of newState: SubSystemState.MovingMassState) -> Bool {
        nextCommandToSend = .autoMove
        autoIfStopCommand = .massStop
        movingMassState = newState
        return true
        //TODO: add a check, make sure it doesn't exceed the limit?
    }
    
    mutating func processStatusMessage(of statusMsg: String) {
        //statusMsg format: "L-STATUS-ready"
        let msgArr = statusMsg.split(separator: "-")
        let typeOfSystem = SystemConstants.SubsystemType(rawValue: String(msgArr[0]))
        let newStatus = SystemConstants.SubsystemStatus(rawValue: String(msgArr[-1]))
        switch typeOfSystem {
        case .Level:
            levellingStatus = newStatus
        case .Gyro:
            gyroStatus = newStatus
        case .Mass:
            movingMassStatus = newStatus
        default:
            break
        }
    }
}

struct SubSystemState {
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

struct SystemConstants {
    enum SubsystemStatus: String {
        case wait = "wait"
        case ready = "ready"
        case busy = "busy"
        case error = "warning"
        case lock = "lock"
    }
    
    enum SubsystemType: String {
        case Level = "L"
        case Mass = "M"
        case Gyro = "G"
    }
}
