//
//  Command.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 28/11/22.
//

import Foundation

struct Command {
    //Authentification
    enum authCommand: String {
        case idAdmin = "IDadmin"
    }
    
    enum controlCommand: String {
        //levelling command
        case upAuto = "A-C-L-up_a-"
        case upManual = "A-C-L-up_m"
        case downAuto = "A-C-L-down_a-"
        case downManual = "A-C-L-down_m"
        case keepLevelOn = "A-C-L-auto"
        case levelStop = "A-C-L-stop"
        
        //moving mass command
        case XPlusManual = "A-C-M-move_x_plus"
        case YPlusManual = "A-C-M-move_y_plus"
        case XStop = "A-C-M-move_x_stop"
        case YStop = "A-C-M-move_y_stop"
        case XMinusManual = "A-C-M-move_x_minus"
        case YMinusManual = "A-C-M-move_y_minus"
        case XAutoSet = "A-C-M-set-" 
        case YAutoSet = "A-C-M-set-X"
        case autoMove = "A-C-M-move"
        case massStop = "A-C-M-stop"
        
        //gyro command, add more
        case autoGyroOn = "A-C-G-auto_on"
        case autoGyroOff = "A-C-G-auto_off"
        case adjustAngleAuto = "A-C-G-move_angle-@"
        case adjustStopAuto = "A-C-G-move_angle_stop"
        case setZero = "A-C-G-zero"
    }
    
}
