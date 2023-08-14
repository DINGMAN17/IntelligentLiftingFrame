//
//  GamepadController.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 7/12/22.
//

import GameController


class GameController: ObservableObject{
    @Published var connected = false
    @Published var state = GCDeviceBattery.State.unknown
    var number = 0
    
    struct element: Identifiable{
        var id = UUID()
        var name: AppConstants.ControlButton
        var pressedAction: (() -> Void)?
        var releasedAction: (() -> Void)?
        var released: String
        var pressed: String
        var state:Bool = false
        var value:Float = 0
        var type: String
    }
    
    @Published var elements:[element] = [
        element(name: .Xminus, released: "chevron.left.circle", pressed: "chevron.left.circle.fill", type: "button"),
        element(name: .Yplus, released: "chevron.up.circle", pressed: "chevron.up.circle.fill", type: "button"),
        element(name: .Xplus, released: "chevron.right.circle", pressed: "chevron.right.circle.fill", type: "button"),
        element(name: .Yminus, released: "chevron.down.circle", pressed: "chevron.down.circle.fill", type: "button"),
        element(name: .up, released: "triangle.circle", pressed: "triangle.circle.fill", type: "button"),
        element(name: .down, released: "multiply.circle", pressed: "multiply.circle.fill", type: "button"),
    ]
    
    init(){
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil, using: didConnectController)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil, using: didDisconnectController)
        GCController.startWirelessControllerDiscovery{}
    }
    
    func didConnectController(_ notification: Notification) {
        connected = true
        let controller = notification.object as! GCController
        print("◦ connected \(controller.productCategory)")
        controller.extendedGamepad?.dpad.left.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 0, pressed) }
        controller.extendedGamepad?.dpad.up.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 1, pressed) }
        controller.extendedGamepad?.dpad.right.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 2, pressed) }
        controller.extendedGamepad?.dpad.down.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 3, pressed) }
        controller.extendedGamepad?.buttonY.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 4, pressed) }
        controller.extendedGamepad?.buttonA.pressedChangedHandler = { (button, value, pressed) in self.button(ofElement: 5, pressed) }
    }
    
    func didDisconnectController(_ notification: Notification) {
        connected = false
        let controller = notification.object as! GCController
        print("◦ disConnected \(controller.productCategory)")
    }
    
    func button(ofElement button: Int, _ pressed: Bool){
        elements[button].state = pressed
    }
    
    func trigger(ofElement button: Int, _ value: Float){
        elements[button].value = value
    }
}

