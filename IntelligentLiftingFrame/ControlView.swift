//
//  ContentView.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 22/11/22.
//

import SwiftUI

struct ControlView: View {
    
    @ObservedObject var controlVM: ControlViewModel
    //@ObservedObject var gamepad = GameController()
    @State private var keepLevelOn = false
    
    
    let directions = ["up", "down", "lateral X", "lateral Y", "rotate"]
    
    var body: some View {
        VStack() {
            drawingConstants.createTitle(AppConstants.appTitle)
            
            HStack(spacing: 500) {
                drawingConstants.createSubTitle(AppConstants.tControl)
                drawingConstants.createSubTitle(AppConstants.rControl)
            }
            .padding(.bottom, 80)
            
            Grid(alignment: .top, horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    createButton(of: AppConstants.ControlButton.Yplus).padding(.leading, 10)
                    TextField(
                      "Input distance",
                      text: $controlVM.inputValue,
                      onCommit: {
                        print($controlVM.inputValue)
                      }
                    ).frame(width: 150.0, height: 100).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
                    HStack(spacing: 110) {
                        Toggle("Auto Gyro", isOn: $controlVM.autoGyroOn)
                            .onChange(of: controlVM.autoGyroOn) { value in
                                if value {
                                    sendToggleCommand(of: AppConstants.ControlToggle.gyroOn)
                                } else {
                                    sendToggleCommand(of: AppConstants.ControlToggle.gyroOff)
                                }
                                        }
                                    .toggleStyle(VerticalToggleStyle())
                        Toggle("Auto Level", isOn: $keepLevelOn)
                                    .toggleStyle(VerticalToggleStyle())
                                    .onChange(of: keepLevelOn) { value in
                                        if value {
                                            sendToggleCommand(of: AppConstants.ControlToggle.levelOn)
                                        } else {
                                            sendToggleCommand(of: AppConstants.ControlToggle.levelOff)
                                        }
                                                }
                        
                    }.padding(.trailing, 30)
                }
                
                
                GridRow {
                    HStack {
                        createButton(of: AppConstants.ControlButton.Xminus)
                        createButton(of: AppConstants.ControlButton.Xplus)
                    }.padding(.bottom, 50)
                    
                    
                    VStack {
                        Text("Select a direction").font(.title3).padding(.top, -30)
                        Picker("Pick a direction", selection: $controlVM.inputDirection) {
                            ForEach(directions, id: \.self) { item in Text(item)}.frame(width: 80).clipped()
                        }.frame(width: 150, height: 50, alignment: .center)
                        Text("Your input: \(controlVM.inputDirection) by \(controlVM.inputValue) unit")
                            .font(.headline).foregroundColor(Color.black).padding(.top, 10)
                    }
                    
                    HStack(spacing: 5) {
                        createButton(of: AppConstants.ControlButton.up)
                        createButton(of: AppConstants.ControlButton.down)
                    }.padding(.trailing, 30)
                    
                }
                
                GridRow {
                    createButton(of: AppConstants.ControlButton.Yminus)
                    HStack(spacing: 110) {
                        Button{sendAutoStopCommand()} label: {
                                    Text("Stop")
                                }
                                .foregroundColor(.red)
                                .frame(width: 75, height: 75)
                                
                                Button(action: {sendAutoStartCommand()}) {
                                    Text("Start")
                                }
                                .foregroundColor(.green)
                                .frame(width: 75, height: 75)
                            }
                            .padding()
                            .buttonStyle(CircleStyle())
                    
                    Button{sendLevelStep()} label: {
                                Text("Step")
                            }
                            .foregroundColor(.gray)
                            .frame(width: 75, height: 75)
                        
                }.padding(.leading, 10)
                
            }
            Spacer()
        }
        
        .padding()
    }
    
    func createButton(of controlButton: AppConstants.ControlButton) -> some View {
        
        Button(action: {
        }, label: {
            Image(systemName:controlButton.rawValue)
                .font(.largeTitle)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 15)
                .stroke(.green, lineWidth: 4))
        }).simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({_ in
                    sendManualPressedCommand(of: controlButton)
                })
                .onEnded({_ in
                    sendManualReleasedCommand()
                }))
         .padding(.horizontal, 90)
        
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

struct CircleStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        Circle()
            .fill()
            .overlay(
                Circle()
                    .fill(Color.white)
                    .opacity(configuration.isPressed ? 0.3 : 0)
            )
            .overlay(
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.white)
                    .padding(4)
            )
            .overlay(
                configuration.label
                    .foregroundColor(.white)
            )
    }
}

struct VerticalToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return VStack(alignment: .leading) {
            configuration.label // <1>
                .font(.system(size: 21, weight: .semibold)).lineLimit(2)
            HStack {
                if configuration.isOn { // <2>
                    Text("On")
                } else {
                    Text("Off")
                }
                Spacer()
                Toggle(configuration).labelsHidden() // <3>
            }
        }
        .frame(width: 100)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(configuration.isOn ? Color.green: Color.gray, lineWidth: 2) // <4>
        )
    }
}


struct AppConstants {
    static let appTitle = "Intelligent Lifting Frame Control Panel"
    static let tControl = "Payload Lateral motion"
    static let rControl = "Levelling & Gyro adjustment"
    
    enum ControlButton: String {
        case Yplus = "arrow.up"
        case Yminus = "arrow.down"
        case Xminus = "arrow.left"
        case Xplus = "arrow.right"
        case up = "arrow.up.circle"
        case down = "arrow.down.circle"
    }
    
    enum ControlToggle {
        case levelOn
        case levelOff
        case gyroOn
        case gyroOff
    }
    
    enum autoDirection: String {
        case up = "up"
        case down = "down"
        case X = "lateral X"
        case Y = "lateral Y"
        case rotation = "rotate"
    }
    
    
    }

struct drawingConstants {
    static func createTitle(_ title: String) -> some View {
        return Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(Color.black)
            .padding(.bottom, 50)
    }
    
    static func createSubTitle(_ subtitle: String) -> Text {
        return Text(subtitle)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(Color.black)
    }
        
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let controlModel = ControlViewModel()
        ControlView(controlVM: controlModel)
        //ControlView()
            .previewInterfaceOrientation(.landscapeRight)
    }
}
