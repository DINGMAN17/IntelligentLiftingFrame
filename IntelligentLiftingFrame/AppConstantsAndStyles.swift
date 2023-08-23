//
//  AppConstantsAndStyles.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 21/6/23.
//

import Foundation
import SwiftUI

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
        case antiSwayOn
        case antiSwayOff
    }
    
    enum autoDirection: String, CaseIterable {
        case clockwise = "rotate clockwise"
        case anticlockwise = "rotate anticlockwise"
        case X = "lateral X"
        case Y = "lateral Y"
        case up = "up"
        case down = "down"
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
