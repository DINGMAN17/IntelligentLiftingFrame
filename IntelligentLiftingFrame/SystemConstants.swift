//
//  SystemConstants.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 14/7/23.
//

import Foundation

struct SystemConstants {
    enum SubsystemType: String {
        case Level = "L"
        case Mass = "M"
        case Gyro = "G"
        case Vision = "V"
    }
    enum SubsystemStatus: String {
        case wait = "wait"
        case ready = "ready"
        case busy = "busy"
        case error = "warning"
        case lock = "lock"
    }
}
