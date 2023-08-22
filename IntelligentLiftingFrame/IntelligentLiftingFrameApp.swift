//
//  IntelligentLiftingFrameApp.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 22/11/22.
//

import SwiftUI

@main
struct IntelligentLiftingFrameApp: App {
    
    @StateObject var controlModel = ControlViewModel()
    @StateObject var recvMsg = MessageViewModel.messageViewModel
    @StateObject var gameController = GameController()
    
    var body: some Scene {
        WindowGroup {
            ControlView(controlVM: controlModel, msgVM: recvMsg, gameController: gameController)
        }
    }
}


