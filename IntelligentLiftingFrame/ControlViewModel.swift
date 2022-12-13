//
//  ControlViewModel.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 29/11/22.
//

//TODO: flip the moving mass manual directions for both X & Y (DONE & TESTED)
//TODO: levelOn, can't move up/down (DONE & TESTED)
//TODO: save mass set value for the previous action (DONE & TESTED)
//TODO: after adjusting angle for gyro, Auto Gyro will be on (DONE & TESTED)
//TODO: status check! SET ZERO are busy command, need to wait for the server to send the status ready messages (intermediate solution: wait for 0.5s to send the next one)
//TODO: send zero before sending auto-on for gyro


import Foundation

class ControlViewModel: ObservableObject {
    
    @Published var inputDirection: String = "up"
    @Published var inputValue: String = "0"
    @Published var autoGyroOn = false
    @Published var sendGyroOnCmd = false
    private var massXMoveValue: String = "0"
    private var massYMoveValue: String = "0"
    
    @Published private var model = SystemTracker()
    
    var releaseStopCommand: Command.controlCommand? {
        return model.releaseStopCommand
    }
    
    var autoStopCommand: Command.controlCommand? {
        return model.autoIfStopCommand
    }
    
    var nextCommand: Command.controlCommand? {
        return model.nextCommandToSend
    }
    
    @Published private var client = initClient()

    private static func initClient() -> Client {
        let client = Client()
        client.start()
        client.send(data: (strToData(Command.authCommand.idAdmin.rawValue)))
        return client
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
            model.processUserInput(of: cmd)
            model.clearReleaseStopAfterSending()
        }
    }
    
    func sendToggleCommand(of toggle: AppConstants.ControlToggle) {
        let toggleCmd = processToggle(of: toggle)
        if let cmd = toggleCmd {
            //sendNextCommand() figure out how long does zero takes
            client.send(data: ControlViewModel.strToData(cmd))
        }
    }
    
    func sendAutoCommand(of direction: AppConstants.autoDirection?) {
        let distance = Int(inputValue) ?? 0
        let autoCmdStr = processAutoAction(of: direction, unit: distance)
        if let cmdStr = autoCmdStr {
            client.send(data: ControlViewModel.strToData(cmdStr))
            sendNextCommand()
            checkGyroState()
        }
    }
    
    func sendAutoStopCommand() {
        if let cmd = autoStopCommand {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
            model.processUserInput(of: cmd)
            model.clearAutoStopAfterSending()
        }
    }
    
    private func processAutoAction(of direction: AppConstants.autoDirection?, unit value: Int) -> String?{
        if direction != nil && value != 0 {
            let autoCmd = getCommandFromAutoActionAndProcessValue(of: direction!, input: value)
            let processedCmd = model.processUserInput(of: autoCmd!)
            if let sendCmd = processedCmd {
                return sendCmd + inputValue
            }
        }
        return nil
    }
    
    private func processButton(of currentButton: AppConstants.ControlButton) -> String? {
        if let currentCommand = getCommandFromButton(currentButton) {
            return model.processUserInput(of: currentCommand)
        } else {
            return nil
        }
    }
    
    private func processToggle(of toggle: AppConstants.ControlToggle) -> String? {
        if let currentCommand = getCommandFromToggle(toggle) {
            return model.processUserInput(of: currentCommand)
        } else {
            return nil
        }
    }
    
    private func sendNextCommand() {
        sleep(1)
        if let nextCmd = nextCommand {
            client.send(data: ControlViewModel.strToData(nextCmd.rawValue))
            model.clearNextCommand()
        }
    }
    
    private func checkGyroState() {
        if model.gyroState == .autoOn {
            autoGyroOn = true
            sendGyroOnCmd = false
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
            return Command.controlCommand.autoGyroOn
        case .gyroOff:
            return Command.controlCommand.autoGyroOff
        case .levelOn:
            return Command.controlCommand.keepLevelOn
        case .levelOff:
            return Command.controlCommand.levelStop
        }
    }
    
    private func getCommandFromAutoActionAndProcessValue(of autoDirection: AppConstants.autoDirection, input value: Int) -> Command.controlCommand? {
        let valueStr = convertNegativeSign(of: value)
        inputValue = valueStr
        switch autoDirection {
        case .up:
            return Command.controlCommand.upAuto
        case .down:
            return Command.controlCommand.downAuto
        case .X:
            processValueForLateralX()
            massXMoveValue = valueStr
            return Command.controlCommand.XAutoSet
        case .Y:
            processValueForLateralY()
            massYMoveValue = valueStr
            return Command.controlCommand.YAutoSet
        case .rotation:
            return Command.controlCommand.adjustAngleAuto
        }
    }
    
    
    private func convertNegativeSign(of value: Int) -> String {
        if value < 0 {
            return "_" + String(abs(value))
        } else {
            return String(value)
        }
    }
    
    private func processValueForLateralY() {
        inputValue = massXMoveValue + ",Y" + inputValue
    }
    
    private func processValueForLateralX() {
        inputValue = "X" + inputValue + ",Y" + massYMoveValue
    }
}
