//
//  ControlViewModel.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 29/11/22.
//

import Foundation

class ControlViewModel: ObservableObject {
    
    static var address = "172.26.62.175"
    static var port: UInt16 = 8080
    private var inputValue: String = "0"
    
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

    private static func initClient(host address: String, port portNumber: UInt16) -> Client {
        let client = Client(host: address, port: portNumber)
        client.start()
        client.send(data: (strToData(Command.authCommand.idAdmin.rawValue)))
        return client
    }

    private var client = initClient(host: ControlViewModel.address, port: ControlViewModel.port)

    func sendPressManualButton(typeOfControlButton button: AppConstants.ControlButton) {
        let cmdToSend = processButton(of: button)
        if let cmd = cmdToSend {
            client.send(data: ControlViewModel.strToData(cmd))
        }
    }
    
    func sendReleaseMnaualButton() {
        let stopCmd = releaseStopCommand
        if let cmd = stopCmd {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
            model.processUserInput(of: cmd)
            model.clearReleaseStopAfterSending()
        }
    }
    
    func sendToggleCommand(of toggle: AppConstants.ControlToggle) {
        let toggleCmd = getCommandFromToggle(toggle)
        if let cmd = toggleCmd {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
        }
    }
    
    func sendAutoCommand(of direction: AppConstants.autoDirection?, unit value: Int) {
        let autoCmdStr = processAutoAction(of: direction, unit: value)
        if let cmdStr = autoCmdStr {
            client.send(data: ControlViewModel.strToData(cmdStr))
            if let nextCmd = nextCommand {
                client.send(data: ControlViewModel.strToData(nextCmd.rawValue))
            }
        }
    }
    
    func sendAutoStopCommand() {
        let stopCmd = autoStopCommand
        if let cmd = stopCmd {
            client.send(data: ControlViewModel.strToData(cmd.rawValue))
            model.processUserInput(of: cmd)
            model.clearAutoStopAfterSending()
        }
    }
    
    private func processAutoAction(of direction: AppConstants.autoDirection?, unit value: Int) -> String?{
        if direction != nil && value != 0 {
            convertNegativeSign(of: value)
            let autoCmd = getCommandFromAutoActionAndProcessValue(of: direction!)
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
    
    private static func strToData(_ inputString: String) -> Data {
        return inputString.data(using: .utf8)!
    }

    private func getCommandFromButton(_ button: AppConstants.ControlButton) -> Command.controlCommand? {
        switch button {
        case .Yplus:
            return Command.controlCommand.YPlusManual
        case .Yminus:
            return Command.controlCommand.YMinusManual
        case .Xminus:
            return Command.controlCommand.XMinusManual
        case .Xplus:
            return Command.controlCommand.XPlusManual
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
    
    private func getCommandFromAutoActionAndProcessValue(of autoDirection: AppConstants.autoDirection) -> Command.controlCommand? {
        switch autoDirection {
        case .up:
            return Command.controlCommand.upAuto
        case .down:
            return Command.controlCommand.downAuto
        case .X:
            processValueForLateralX()
            return Command.controlCommand.XAutoSet
        case .Y:
            processValueForLateralY()
            return Command.controlCommand.YAutoSet
        case .rotation:
            return Command.controlCommand.adjustAngleAuto
        }
    }
    
    
    private func convertNegativeSign(of value: Int) {
        if value < 0 {
            inputValue = "_" + String(abs(value))
        } else {
            inputValue = String(value)
        }
    }
    
    private func processValueForLateralY() {
        inputValue = "Y" + inputValue
    }
    
    private func processValueForLateralX() {
        inputValue = "X" + inputValue + ",Y0"
    }
}
