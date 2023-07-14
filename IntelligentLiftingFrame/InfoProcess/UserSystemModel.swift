//
//  Parser.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 28/11/22.
//

import Foundation

class InfoProcessModel{
    
    var systemTracker: SystemTracker
    
    static let infoProgressModel = InfoProcessModel()
    
    private init() {
        systemTracker = SystemTracker()
    }
}

struct SystemTracker {
    //action state
    private (set) var movingMassState = SubSystemState.MovingMassState.stop
    private (set) var levellingState = SubSystemState.LevellingState.stop
    private (set) var gyroState = SubSystemState.GyroState.stop
    //status
    private (set) var movingMassStatus: SystemConstants.SubsystemStatus?
    private (set) var levellingStatus: SystemConstants.SubsystemStatus?
    private (set) var gyroStatus: SystemConstants.SubsystemStatus?
    private (set) var visionStatus: SystemConstants.SubsystemStatus?
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
            toSendCmd = processMassMoveManual(of: .moveManualX)
        case .YMinusManual, .YPlusManual:
            toSendCmd = processMassMoveManual(of: .moveManualY)
        case .YStop, .XStop:
            movingMassState = .stop
        case .antiSwayOn:
            toSendCmd = processAntiSwayOn()
        case .antiSwayOff:
            toSendCmd = processAntiSwayOff()
        case .upManual:
            toSendCmd = processLevelMoveManual(of: .manualUp)
        case .downManual:
            toSendCmd = processLevelMoveManual(of: .manualDown)
        case .keepLevelOn:
            levellingState = .keepLevel
            toSendCmd = true
        case .levelStop:
            levellingState = .stop
            toSendCmd = true
        case .autoGyroOn:
            toSendCmd = processGyroAutoOn()
        case .autoGyroOff:
            gyroState = .autoOff
            toSendCmd = true
        case .upAuto:
            toSendCmd = processLevelMoveAuto(of: .autoUp)
        case .downAuto:
            toSendCmd = processLevelMoveAuto(of: .autoDown)
        case .YAutoSet:
            toSendCmd = processMassSet(of: .moveAutoX)
        case .XAutoSet:
            toSendCmd = processMassSet(of: .moveAutoY)
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
    
    mutating func processAntiSwayOn() -> Bool {
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Mass) {
            return false
        } else {
            movingMassState = .antiSwayOn
            return true
        }
    }
    
    mutating func processAntiSwayOff() -> Bool {
        //TODO: need to send command to move moving mass to origin
        movingMassState = .antiSwayOff
        return true
    }

    mutating func processGyroAutoOn() -> Bool {
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Gyro) {
            return false
        } else {
            gyroState = .autoOn
            return true
        }
    }
    
    mutating func processMassMoveManual(of newState: SubSystemState.MovingMassState) -> Bool {
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Mass) {
            return false
        }
        if newState != movingMassState {
            movingMassState = newState
            if newState == .moveManualX {
                releaseStopCommand = Command.controlCommand.XStop
            } else if newState == .moveManualY {
                releaseStopCommand = Command.controlCommand.YStop
            }
            return true
        }
        return false
    }
    
    mutating func processLevelMoveManual(of newState: SubSystemState.LevellingState) -> Bool {
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Level) {
            return false
        }
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
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Level) {
            return false
        }
        if levellingState != .keepLevel {
            levellingState = newState
            autoIfStopCommand = Command.controlCommand.levelStop
            return true
        } else {
            return false
        }
    }
    
    mutating func processMassSet(of newState: SubSystemState.MovingMassState) -> Bool {
        if !checkSystemStatus(system: SystemConstants.SubsystemType.Mass) {
            return false
        }
        nextCommandToSend = .autoMove
        autoIfStopCommand = .massStop
        movingMassState = newState
        return true
        //TODO: add a check, make sure it doesn't exceed the limit?
    }
    
    mutating func processStatusMessage(of statusMsg: String) -> (systemType: SystemConstants.SubsystemType?, systemStatus: String){
        //statusMsg format: "L-STATUS-ready"
        let msgArr = statusMsg.split(separator: "-")
        let typeOfSystem = SystemConstants.SubsystemType(rawValue: String(msgArr[0]))
        let newStatus = SystemConstants.SubsystemStatus(rawValue: String(msgArr[2]))
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
        return (typeOfSystem, String(msgArr[2]))
    }
    
    func checkSystemStatus(system: SystemConstants.SubsystemType) -> Bool {
        let readyStatus = SystemConstants.SubsystemStatus.ready
        switch system {
        case.Gyro:
            return gyroStatus == readyStatus
        case .Mass:
            return movingMassStatus == readyStatus
        case .Level:
            return levellingStatus == readyStatus
        case .Vision:
            return visionStatus == readyStatus
        }
    }
}

struct SubSystemState {
    enum MovingMassState {
        case antiSwayOn
        case antiSwayOff
        case moveManualX
        case moveManualY
        case moveAutoX
        case moveAutoY
        case stop
    }
    
    enum LevellingState {
        case levelOnce
        case keepLevel
        case autoUp
        case autoDown
        case manualUp
        case manualDown
        case stop
    }
    
    enum GyroState {
        case autoOn
        case autoOff
        case adjustAngle
        case stop
    }
}
