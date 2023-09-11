//
//  ControlViewModel.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 29/11/22.
//

import Foundation

class ControlViewModel: ObservableObject {
    
    let minimumAngle = 0.5
    
    @Published var inputDirection: AppConstants.autoDirection = .clockwise
    @Published var inputValue: String = "0"
    @Published var autoGyroOn = false
    @Published var sendGyroOnCmd = true
    @Published var antiSwayOn = false
    @Published var autoLevelOn = false
    
    @Published var address = "192.168.1.3"
    var port: UInt16 = 8080

    @Published var connect = false
    private var inputDistance: String = "0"
    private var massXMoveValue: String = "0"
    private var massYMoveValue: String = "0"
    
    @Published var model = InfoProcessModel.infoProgressModel
    
    var releaseStopCommand: Command.controlCommand? {
        return model.systemTracker.releaseStopCommand
    }
    
    var autoStopCommand: Command.controlCommand? {
        return model.systemTracker.autoIfStopCommand
    }
    
    var nextCommand: Command.controlCommand? {
        return model.systemTracker.nextCommandToSend
    }
    
    var unit: String {
        switch inputDirection {
        case .clockwise:
            return "degree"
        case .anticlockwise:
            return "degree"
        case .X:
            return "steps"
        case .Y:
            return "steps"
        case .up:
            return "mm"
        case .down:
            return "mm"
        }
    }
    
    private lazy var client: Client = {
        initClient(host: self.address, port: self.port)
    }()
    
    private func initClient(host address: String, port portNumber: UInt16) -> Client {
        Client(host: address, port: portNumber)
    }

    func establishClientConnection()  {
        client.start()
        client.send(data: (ControlViewModel.strToData(Command.authCommand.idAdmin.rawValue + "\n")))
    }
    
    func sendEstopCommand() {
        let cmdToSend = model.systemTracker.processUserInput(of: .Estop)
        client.send(data: ControlViewModel.strToData(cmdToSend!))
    }

    func sendPressManualButton(typeOfControlButton button: AppConstants.ControlButton) {
        let cmdToSend = processButton(of: button)
        if let cmd = cmdToSend {
            client.send(data: ControlViewModel.strToData(cmd))
        }
    }
    
    func sendReleaseMnaualButton() {
        if let cmd = releaseStopCommand {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
            model.systemTracker.processUserInput(of: cmd)
            model.systemTracker.clearReleaseStopAfterSending()
        }
    }
    
    func sendToggleCommand(of toggle: AppConstants.ControlToggle) -> Bool {
        let toggleCmd = processToggle(of: toggle)
        if let cmd = toggleCmd {
            client.send(data: ControlViewModel.strToData(cmd))
            return true
        }
        return false
    }
    
    func sendAutoCommand(of direction: AppConstants.autoDirection?) {
        let distance = Double(inputValue) ?? 0
        let autoCmdStr = processAutoAction(of: direction, unit: distance)
        if let cmdStr = autoCmdStr {
            client.send(data: ControlViewModel.strToData(cmdStr))
            print("sent auto command: ", cmdStr)
            checkGyroState()
            sendNextCommand()
        }
    }
    
    func sendAutoStopCommand() {
        if let cmd = autoStopCommand {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
            model.systemTracker.processUserInput(of: cmd)
            model.systemTracker.clearAutoStopAfterSending()
        }
    }
    
    func sendRequestForStatusUpdate() {
        let cmd = Command.checkCommand.AllStatus
        client.send(data: ControlViewModel.strToData(cmd.rawValue))
    }
    
    func sendLevelStep() {
        let stepCommand = Command.controlCommand.levelStep.rawValue
        client.send(data: ControlViewModel.strToData(stepCommand))
    }
    
    private func processAutoAction(of direction: AppConstants.autoDirection?, unit value: Double) -> String?{
        if direction != nil {
            let autoCmd = getCommandFromAutoActionAndProcessValue(of: direction!, input: value)
            let processedCmd = model.systemTracker.processUserInput(of: autoCmd!)
            if let sendCmd = processedCmd {
                return sendCmd + inputDistance
            }
        }
        return nil
    }
    
    private func processButton(of currentButton: AppConstants.ControlButton) -> String? {
        if let currentCommand = getCommandFromButton(currentButton) {
            return model.systemTracker.processUserInput(of: currentCommand)
        } else {
            return nil
        }
    }
    
    private func processToggle(of toggle: AppConstants.ControlToggle) -> String? {
        if let currentCommand = getCommandFromToggle(toggle) {
            return model.systemTracker.processUserInput(of: currentCommand)
        } else {
            return nil
        }
    }
    
    private func sendNextCommand() {
        sleep(1)
        if let nextCmd = nextCommand {
            client.send(data: ControlViewModel.strToData(nextCmd.rawValue))
            model.systemTracker.clearNextCommand()
        }
    }
    
    private func checkGyroState() {
        if model.systemTracker.gyroState == .autoOn {
            autoGyroOn = true
            sendGyroOnCmd = false
        } else {
            sendGyroOnCmd = true
        }
    }
    
    private static func strToData(_ inputString: String) -> Data {
        return inputString.data(using: .utf8)!
    }

    private func getCommandFromButton(_ button: AppConstants.ControlButton) -> Command.controlCommand? {
        switch button {
        case .Yplus:
            return Command.controlCommand.YMinusManual
        case .Yminus:
            return Command.controlCommand.YPlusManual
        case .Xminus:
            return Command.controlCommand.XPlusManual
        case .Xplus:
            return Command.controlCommand.XMinusManual
        case .up:
            return Command.controlCommand.upManual
        case .down:
            return Command.controlCommand.downManual
        }
    }
    
    private func getCommandFromToggle(_ toggle: AppConstants.ControlToggle) -> Command.controlCommand? {
        switch toggle {
        case .gyroOn:
            checkGyroState()
            if sendGyroOnCmd == true {
                return Command.controlCommand.autoGyroOn
            } else {
                return nil
            }
        case .gyroOff:
            return Command.controlCommand.autoGyroOff
        case .levelOn:
            return Command.controlCommand.keepLevelOn
        case .levelOff:
            return Command.controlCommand.levelStop
        case .antiSwayOn:
            return Command.controlCommand.antiSwayOn
        case .antiSwayOff:
            return Command.controlCommand.antiSwayOff
        }
    }
    
    private func getCommandFromAutoActionAndProcessValue(of autoDirection: AppConstants.autoDirection, input value: Double) -> Command.controlCommand? {
        
        let valueStr = convertNegativeSign(of: value)
        inputDistance = valueStr
        
        switch autoDirection {
        case .up:
            inputDistance = String(Int(value))
            return Command.controlCommand.upAuto
        case .down:
            inputDistance = String(Int(value))
            return Command.controlCommand.downAuto
        case .X:
            inputDistance = processValueForLateralX()
            massXMoveValue = valueStr
            return Command.controlCommand.XAutoSet
        case .Y:
            inputDistance = processValueForLateralY()
            massYMoveValue = valueStr
            return Command.controlCommand.YAutoSet
        case .clockwise:
            inputDistance = checkAndProcessValueForAngle(input: value)
            return Command.controlCommand.adjustAngleAuto
        case .anticlockwise:
            inputDistance = checkAndProcessValueForAngle(input: value)
            return Command.controlCommand.adjustAngleAuto
        }
    }
    
    
    private func convertNegativeSign(of value: Double) -> String {
        if value < 0 {
            return "_" + String(abs(Int(value)))
        } else {
            return String(Int(value))
        }
    }
    
    private func checkAndProcessValueForAngle(input value: Double) -> String {
        var angleToAdjust = "0.5"
        if value > 0 {
            angleToAdjust = String(value)
        }
        if inputDirection == .anticlockwise {
            angleToAdjust = "_" + angleToAdjust
        }
        return angleToAdjust
    }
    
    private func processValueForLateralY() -> String {
        return massXMoveValue + ",Y" + inputDistance
    }
    
    private func processValueForLateralX() -> String {
        return "X" + inputDistance + ",Y" + massYMoveValue
    }
}
