//
//  ContentView.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 22/11/22.
//

import SwiftUI

struct ControlView: View {
    
    @ObservedObject var controlVM: ControlViewModel
    @ObservedObject var msgVM: MessageViewModel
    
    @State private var isSchemeticViewVisible = true
    
    let directions = ["up", "down", "lateral X", "lateral Y", "rotate"]
    
    var body: some View {
        VStack() {
            drawingConstants.createTitle(AppConstants.appTitle)
            VStack {
                Toggle("Top View On", isOn: $isSchemeticViewVisible)
                    .padding()
                    .fixedSize()

                if isSchemeticViewVisible {
                    createSchemeticView()
                } else {
                    create360View()
                }
            }
            
            Grid(alignment: .top, horizontalSpacing: -70, verticalSpacing: 15) {
                
                GridRow {
                    createButton(of: AppConstants.ControlButton.Yplus, systemStatus: msgVM.recvMassStatus).padding(.leading, 10)
                    
                    HStack(spacing: 50) {
                        createToggleAntiSway()
                        createToggleAutoGyro()
                        createToggleAutoLevel()
                    }.padding(.trailing, 50)
                    
                    createInputDistance()
                }
                
                GridRow {
                    HStack(spacing: -30) {
                        createButton(of: AppConstants.ControlButton.Xminus, systemStatus: msgVM.recvMassStatus)
                        createButton(of: AppConstants.ControlButton.Xplus, systemStatus: msgVM.recvMassStatus)
                    }.padding(.bottom, 2)
                    
                    HStack(spacing: -80) {
                        HStack(spacing: -100) {
                            createButton(of: AppConstants.ControlButton.up, systemStatus: msgVM.recvLevelStatus)
                            createButton(of: AppConstants.ControlButton.down, systemStatus: msgVM.recvLevelStatus)
                        }
                        
                    }//.padding(.trailing, -50)
                    
                    createAutoMoveInput()
                }
                
                GridRow {
                    createButton(of: AppConstants.ControlButton.Yminus, systemStatus: msgVM.recvMassStatus)
                    
                    HStack(spacing: 100) {
                        createStepButton()
                        createIpAddressInput()
                    }
                    
                    HStack(spacing: 110) {
                                            createAutoStopButton()
                                            createAutoStartButton()
                                        }
                                            .padding()
                                            .buttonStyle(CircleStyle())
                }
                
                GridRow {
                    createStatusViewForAllSystems()
                    createShowUpdates()
                    createDataDisplay()
                }
            }
            Spacer()
        }
        .padding()
    }
    
    func create360View() -> some View {
        HStack() {
            BirdsEyeView()
        }
        .frame(width: 800, height: 300)
        .padding(.bottom, 20)
    }
    
    func createSchemeticView() -> some View {
        HStack() {
            SchematicView(data: msgVM)
        }
        .frame(width: 800, height: 300)
        .padding(.bottom, 20)
    }
    
    func createInputDistance() -> some View {
        TextField(
          "Input distance",
          text: $controlVM.inputValue,
          onCommit: {
            print($controlVM.inputValue)
          }
        ).frame(width: 150.0, height: 100).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
    }
    
    func createToggleAntiSway() -> some View{
        
        Toggle("Anti Sway", isOn: $msgVM.antiSwayOn)
            .toggleStyle(VerticalToggleStyle())
            .onChange(of: msgVM.antiSwayOn) { value in
                controlVM.$antiSwayOn = msgVM.$antiSwayOn
                if value {
                    sendToggleCommand(of: AppConstants.ControlToggle.antiSwayOn)
                } else {
                    sendToggleCommand(of: AppConstants.ControlToggle.antiSwayOff)
                }
            }
    }
    
    func createToggleAutoGyro() -> some View{
        Toggle("Auto Gyro", isOn: $controlVM.autoGyroOn)
            .toggleStyle(VerticalToggleStyle())
            .disabled(!(msgVM.recvGyroStatus=="ready"))
            .onChange(of: controlVM.autoGyroOn) { value in
                if value {
                    sendToggleCommand(of: AppConstants.ControlToggle.gyroOn)
                } else {
                    sendToggleCommand(of: AppConstants.ControlToggle.gyroOff)
                }
            }
    }
    
    func createToggleAutoLevel() -> some View {
        Toggle("Auto Level", isOn: $controlVM.autoLevelOn)
            .toggleStyle(VerticalToggleStyle())
            .disabled(!(msgVM.recvLevelStatus=="ready"))
            .onChange(of: controlVM.autoLevelOn) { value in
                if value {
                    sendToggleCommand(of: AppConstants.ControlToggle.levelOn)
                } else {
                    sendToggleCommand(of: AppConstants.ControlToggle.levelOff)
                }
        }
    }
    
    func createAutoStopButton() -> some View {
        Button{sendAutoStopCommand()} label: {
                    Text("Stop")
                .bold()
                .font(.title2)
                }
            .foregroundColor(.red)
            .frame(width: 100, height: 100)
    }
    
    func createAutoStartButton() -> some View {
        Button(action: {sendAutoStartCommand()}) {
                    Text("Start")
                .bold()
                .font(.title2)
                }
                .foregroundColor(.green)
                .frame(width: 100, height: 100)
    }
    
    func createAutoMoveInput() -> some View {
        VStack {
            Text("Select a direction").font(.title3).padding(.top, -30)
            Picker("Pick a direction", selection: $controlVM.inputDirection) {
                ForEach(directions, id: \.self) { item in Text(item)}.frame(width: 80).clipped()
            }.frame(width: 150, height: 50, alignment: .center)
            let unit = getUnitBasedOnInputDirection()
            Text("Your input: \(controlVM.inputDirection) by \(controlVM.inputValue) \(unit)")
                .font(.headline).foregroundColor(Color.black).padding(.top, 10)
        }
    }
    
    func getUnitBasedOnInputDirection() -> String {
        return ""
    }
    
    func createShowUpdates() -> some View {
        HStack {
            Text("Update: ")
                .font(.headline)
                .foregroundColor(Color.black)
            Text(msgVM.recvInfo)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .fontWeight(.bold)
        }.padding(.top, 10)
        
    }
    
    func createIpAddressInput() -> some View {
        TextField(
          "Input distance",
          text: $controlVM.address,
          onCommit: {
            print($controlVM.address)
            establishConnection()
          }
        ).frame(width: 150.0, height: 100).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
    }
    
    func createStepButton() -> some View {
        Button{sendLevelStep()} label: {
                    Text("Step")
        }
            .foregroundColor(.gray)
            .frame(width: 75, height: 75)
    }

    
    func createButton(of controlButton: AppConstants.ControlButton, systemStatus: String) -> some View {
        
        Button(action: {
        }, label: {
            Image(systemName:controlButton.rawValue)
                .font(.system(size: 57))
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .stroke(.green, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    )
        })
        .disabled(!(systemStatus=="ready"))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({_ in
                    sendManualPressedCommand(of: controlButton)
                })
                .onEnded({_ in
                    sendManualReleasedCommand()
                }))
         .padding(.horizontal, 90)
        
    }
    
    func createStatusViewForAllSystems() -> some View {
        VStack(spacing: 10) {
            //drawingConstants.createSubTitle(AppConstants.tControl)
            HStack {
                Text("Level status: ")
                    .font(.headline).foregroundColor(Color.black)
                createStatusView(of: msgVM.recvLevelStatus)
            }
            HStack {
                Text("Mass status: ")
                    .font(.headline).foregroundColor(Color.black)
                createStatusView(of: msgVM.recvMassStatus)
            }
            HStack {
                Text("Gyro status: ")
                    .font(.headline).foregroundColor(Color.black)
                createStatusView(of: msgVM.recvGyroStatus)
            }
        }
    }
    
    func createStatusView(of statusStr: String) -> some View {
        //TODO: add other status like error
        if statusStr == "ready" {
            return Text("READY")
                .font(.headline)
                .foregroundColor(.green)
        } else if statusStr == "busy" {
            return Text("BUSY")
                .font(.headline)
                .foregroundColor(.yellow)
        } else {
            return Text(statusStr)
                .font(.headline)
                .foregroundColor(.red)
        }
    }
    
    func createDataDisplay() -> some View {
        HStack(spacing: 80) {
//            VStack(spacing: 5) {
//                HStack {
//                    Text("X: ")
//                        .font(.headline).foregroundColor(Color.black)
//                    Text(msgVM.recvData.x.description)
//                }
//                HStack {
//                    Text("Y: ")
//                        .font(.headline).foregroundColor(Color.black)
//                    Text(msgVM.recvData.y.description)
//                }
//                HStack {
//                    Text("Z: ")
//                        .font(.headline).foregroundColor(Color.black)
//                    Text(msgVM.recvData.z.description)
//                }
//            }
            VStack(spacing: 5) {
//                HStack {
//                    Text("Yaw: ")
//                        .font(.headline).foregroundColor(Color.black)
//                    Text(msgVM.recvData.yaw.description)
//                }
                HStack {
                    Text("Roll: ")
                        .font(.headline).foregroundColor(Color.black)
                    Text(msgVM.recvData.roll.description)
                }
                HStack {
                    Text("Pitch: ")
                        .font(.headline).foregroundColor(Color.black)
                    Text(msgVM.recvData.pitch.description)
                }
            }
        }
    }
    
    func establishConnection() {
        controlVM.establishClientConnection()
    }
    
    func sendManualPressedCommand(of controlButton: AppConstants.ControlButton) {
        controlVM.sendPressManualButton(typeOfControlButton: controlButton)
    }
    
    func sendManualReleasedCommand() {
        controlVM.sendReleaseMnaualButton()
    }
    
    func sendToggleCommand(of toggle: AppConstants.ControlToggle) {
        controlVM.sendToggleCommand(of: toggle)
    }
    
    func sendAutoStartCommand() {
        let autoDirection = AppConstants.autoDirection(rawValue: controlVM.inputDirection)
        controlVM.sendAutoCommand(of: autoDirection)
    }
    
    func sendAutoStopCommand() {
        controlVM.sendAutoStopCommand()
    }
    
    func sendLevelStep() {
        controlVM.sendLevelStep()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let controlModel = ControlViewModel()
        let messageVM = MessageViewModel.messageViewModel
        ControlView(controlVM: controlModel, msgVM: messageVM)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
