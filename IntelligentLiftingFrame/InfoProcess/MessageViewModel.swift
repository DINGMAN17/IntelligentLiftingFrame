//
//  DataProcessor.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 9/2/23.
//

import Foundation

class MessageViewModel: ObservableObject {
    
    @Published var recvInfo: String
    @Published var recvLevelStatus: String
    @Published var recvMassStatus: String
    @Published var recvGyroStatus: String
    @Published var recvError: String
    @Published var recvData: PPVCState
    
    @Published var antiSwayOn: Bool
    @Published var model = InfoProcessModel.infoProgressModel
    
    static let messageViewModel = MessageViewModel()
    
    private init() {
        recvInfo = ""
        recvLevelStatus = ""
        recvMassStatus = ""
        recvGyroStatus = ""
        recvError = ""
        recvData = PPVCState()
        antiSwayOn = false
    }
    
    func processMsgFromServer(of msg: String) {
        //TODO: catch errors, split based on \n
        let trimmedRawMsg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        let msg_list = trimmedRawMsg.components(separatedBy: "\n")
        for singleMsg in msg_list {
            processSingleMsg(of: singleMsg)
        }
    }
    
    func processSingleMsg(of msg: String) {
        let trimmedMsg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        let msgComponents = trimmedMsg.components(separatedBy: "-")
        if let msgType = MessageType(rawValue: msgComponents[1]) {
            let msgContent = msgComponents[2]
            switch msgType  {
            case .status:
                updateStatusFromServer(of: trimmedMsg)
            case .data:
                updateDataFromServer(of: trimmedMsg)
            case .info:
                if msgContent.hasPrefix("ANTISWAYAUTODONE") {
                    updateMassStatusFromInfo(of: msgContent)
                } else {
                    updateInfoFromServer(of: msgContent)
                }
            case .error:
                updateErrorFromServer(of: msgContent)
            case .debug:
                updateInfoFromServer(of: trimmedMsg)
            }
        }
    }
    
    func updateInfoFromServer(of msg: String) {
        DispatchQueue.main.async {
            self.recvInfo = msg
        }
    }
    
    func updateMassStatusFromInfo(of msgContent: String) {
        DispatchQueue.main.async {
            self.antiSwayOn = false
        }
    }
    
    func updateStatusFromServer(of msg: String) {
        let results = model.systemTracker.processStatusMessage(of: msg)
        DispatchQueue.main.async {
            switch results.systemType {
            case .Gyro:
                self.recvGyroStatus = results.systemStatus
            case .Level:
                self.recvLevelStatus = results.systemStatus
            case .Mass:
                self.recvMassStatus = results.systemStatus
            default:
                break
            }
        }
    }
    
    func updateErrorFromServer(of msg: String) {
        //TODO: more things to do with error!
        DispatchQueue.main.async {
            self.recvError = msg
        }
    }
    
    func updateDataFromServer(of msg: String) {
        //TODO: CHECK WHETHER THE DATA IS OF THE FORMAT
        let msgComponents = msg.components(separatedBy: "-")
        let subSystemType = SystemConstants.SubsystemType(rawValue: msgComponents[0])
        let newData = msgComponents[2]
        DispatchQueue.main.async {
            switch subSystemType {
            case .Level:
                if newData.hasPrefix("1") {
                    self.recvData.updateRollPitch(newMsg: msg)
                }
            case .Mass:
//                self.recvData.updateLateralPos(newPos: newData)
                print(newData)
            case .Gyro:
//                self.recvData.updateYaw(newYaw: msg)
                print(newData)
            case .Vision:
                self.recvData.updateVisionData(newMsg: msg)
            case .none:
                print(msg)
            }
        }
    }
    
    func getAvgYaw() -> Double {
        let recentYawList = self.recvData.recentYawList
        let sum = recentYawList.reduce(0) {$0 + $1}
        let avg = recentYawList.isEmpty ? 0.0 : sum / Double(recentYawList.count)
        return (avg * 10).rounded()/10
    }
    
    enum MessageType: String {
        case status = "STATUS"
        case info = "INFO"
        case data = "D"
        case error = "ERROR"
        case debug = "DEBUG"//TODO: wait for implementation on the server side
    }
}

struct PPVCState {
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
    var isAligned: Bool = true
    
    var yaw: Double = 0.0
    var roll: Double = 0.0
    var pitch: Double = 0.0
    
    var massX: Double = 0.0
    var massY: Double = 0.0
    
    var recentYawList: [Double] = []
    
    mutating func updateLateralPos(newPos: String) {
        //TODO: check how to parse data from moving mass
        //now assume X100Y200
        let substrings = newPos.components(separatedBy: "Y")
        let xPos = substrings[0].substring(from: 1)
        let yPos = substrings[1]
        self.massX = Double(xPos) ?? 0.0
        self.massY = Double(yPos) ?? 0.0
    }
    
    mutating func updateYaw(newYaw: String) {
        let angleArray = newYaw.components(separatedBy: "D")
        let newYaw = angleArray[1].substring(from: 1)
        self.yaw = Double(newYaw) ?? 0.0
        
    }
    
    mutating func updateYawList() {
        //add the most recent reading to a list for calculating the average
        self.recentYawList.append(self.yaw)
        if self.recentYawList.count > 5 {
            self.recentYawList.removeFirst()
        }
    }
    
    mutating func updateRollPitch(newMsg: String) {
        //assume L-D-1,-0.55,0.46
        let angleArray = newMsg.components(separatedBy: ",")
        self.roll = Double(angleArray[1]) ?? 0.0
        self.pitch = Double(angleArray[2]) ?? 0.0
    }
    
    mutating func updateVisionData(newMsg: String) {
        let dataArr = newMsg.components(separatedBy: ",")
        self.x = Double(dataArr[1]) ?? 0.0
        self.y = Double(dataArr[2]) ?? 0.0
        self.z = Double(dataArr[3]) ?? 0.0
        self.yaw = Double(dataArr[4]) ?? 0.0
        self.updateYawList()
        //change alignment status threshold here
        if (abs(self.x) < 20 && abs(self.y) < 20 && abs(self.yaw) < 1) {
            self.isAligned = true
        }
        else{self.isAligned = false}
    }
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
            let fromIndex = index(from: from)
            return String(self[fromIndex...])
        }
}
