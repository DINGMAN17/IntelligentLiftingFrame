//
//  JoystickView.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 14/8/23.
//

import SwiftUI

struct JoystickView: View {
    @StateObject private var gameController = GameController()
    
    var body: some View {
        VStack {
            Text("Game Controller Status: \(gameController.connected ? "Connected" : "Disconnected")")
            
            ForEach(gameController.elements) { controlElement in
                Button(action: {
                    gameController.button(ofElement: 0, true)
                }) {
                    Image(systemName: controlElement.state ? controlElement.pressed : controlElement.released)
                }
            }
        }
    }
}


