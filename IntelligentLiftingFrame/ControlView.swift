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
    @ObservedObject var gameController: GameController
    
    @State private var isSchemeticViewVisible = true
    @State var allowJoystick = false
    
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
                    createButton(of: AppConstants.ControlButton.Yplus, systemStatus: msgVM.recvMassStatus, ofElement: 1).padding(.leading, 10)
                    
                    HStack(spacing: 50) {
                        createToggleAntiSway()
                        createToggleAutoGyro()
                        createToggleAutoLevel()
                    }.padding(.trailing, 50)
                    
                    createInputDistance()
                }
                
                GridRow {
                    HStack(spacing: -30) {
                        createButton(of: AppConstants.ControlButton.Xminus, systemStatus: msgVM.recvMassStatus, ofElement: 0)
                        createButton(of: AppConstants.ControlButton.Xplus, systemStatus: msgVM.recvMassStatus, ofElement: 2)
                    }.padding(.bottom, 2)
                    
                    HStack(spacing: -80) {
                        HStack(spacing: -100) {
                            createButton(of: AppConstants.ControlButton.up, systemStatus: msgVM.recvLevelStatus, ofElement: 4)
                            createButton(of: AppConstants.ControlButton.down, systemStatus: msgVM.recvLevelStatus, ofElement: 5)
                            createStepButton()
                        }
                        
                    }//.padding(.trailing, -50)
                    
                    createAutoMoveInput()
                }
                
                GridRow {
                    createButton(of: AppConstants.ControlButton.Yminus, systemStatus: msgVM.recvMassStatus, ofElement: 3)
                    
                    HStack(spacing: 70) {
                        createAllowJoystickToggle()
                        createIpAddressInput()
                    }.padding(.trailing, 90)
                    
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
        HStack{
            TextField(
              "Input distance",
              text: $controlVM.inputValue,
              onCommit: {
                print($controlVM.inputValue)
              }
            ).frame(width: 150.0, height: 100).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            
            Button(action: {
                getRecommendedYaw()//get latest yaw value
            }, label: {
                Image(systemName:"location.magnifyingglass")
                    .font(.title)
            })
        }
    }
    
    func getRecommendedYaw() {
        let avgYaw = msgVM.getAvgYaw()
        if (avgYaw >= 0) {
            controlVM.inputValue = String(avgYaw)
            controlVM.inputDirection = .clockwise
        } else {
            controlVM.inputDirection = .anticlockwise
            controlVM.inputValue = String(abs(avgYaw))
        }
    }
    
    func createAllowJoystickToggle() -> some View {
        Toggle(isOn: $allowJoystick) {
            Label("", systemImage: "gamecontroller")
        }
            .padding()
            .fixedSize()
            .font(.title)
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
            Picker("Select a direction", selection: $controlVM.inputDirection) {
                ForEach(AppConstants.autoDirection.allCases, id: \.self) { direction in Text(direction.rawValue)
                        .font(.title)
                }
            }
            .frame(width: 200, height: 50, alignment: .center)
            let unit = getUnitBasedOnInputDirection()
            Text("Your input: \(controlVM.inputDirection.rawValue) by \(controlVM.inputValue) \(controlVM.unit)")
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
            .opacity(0.4)
            .frame(width: 75, height: 75)
            .padding(.leading, 50)
    }

    
    func createButton(of controlButton: AppConstants.ControlButton, systemStatus: String, ofElement elementIndex: Int) -> some View {
        
        Button(action: {
            gameController.button(ofElement: elementIndex, true)
        }, label: {
            Image(systemName:controlButton.rawValue)
                .font(.system(size: 57))
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .stroke(.green, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .background(gameController.elements[elementIndex].state && allowJoystick ? Color.green : Color.clear)
                    )
        })
        .onChange(of: gameController.elements[elementIndex].state) { newState in
            //only execute when the gamepad toggle button is on 
            if (allowJoystick) {
                if newState {
                    // Execute function when button is pressed
                    print(controlButton.rawValue)
                    sendManualPressedCommand(of: controlButton)
                } else {
                    // Execute function when button is released
                    sendManualReleasedCommand()
                }
            }
        }
        .disabled(!(systemStatus=="ready"))
        .padding(.horizontal, 90)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({_ in
                    sendManualPressedCommand(of: controlButton)
                })
                .onEnded({_ in
                    sendManualReleasedCommand()
        }))
    }
    
    
    func createStatusViewForAllSystems() -> some View {
        VStack(spacing: 10) {
            //drawingConstants.createSubTitle(AppConstants.tControl)
            HStack {
                createCheckButtonForStatusView(systemName: SystemConstants.SubsystemType.Level)
                createStatusView(of: msgVM.recvLevelStatus)
            }
            HStack {
                createCheckButtonForStatusView(systemName: SystemConstants.SubsystemType.Mass)
                createStatusView(of: msgVM.recvMassStatus)
            }
            HStack {
                createCheckButtonForStatusView(systemName: SystemConstants.SubsystemType.Gyro)
                createStatusView(of: msgVM.recvGyroStatus)
            }
        }
    }
    
    func createCheckButtonForStatusView(systemName: SystemConstants.SubsystemType) -> some View {
        Button(action: {
                        sendRequestForStatusUpdate()
                    }) {
                        Text(systemName.rawValue)
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
            VStack(spacing: 5) {
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
        controlVM.sendAutoCommand(of: controlVM.inputDirection)
    }
    
    func sendAutoStopCommand() {
        controlVM.inputValue = String(0) //remove auto input to prevent user's mistakes
        controlVM.sendAutoStopCommand()
    }
    
    func sendLevelStep() {
        controlVM.sendLevelStep()
    }
    
    func sendRequestForStatusUpdate() {
        controlVM.sendRequestForStatusUpdate()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let controlModel = ControlViewModel()
        let messageVM = MessageViewModel.messageViewModel
        let gameController = GameController()
        ControlView(controlVM: controlModel, msgVM: messageVM, gameController: gameController)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
