//
//  IntelligentLiftingFrameApp.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 22/11/22.
//

import SwiftUI

@main
struct IntelligentLiftingFrameApp: App {
    var body: some Scene {
        WindowGroup {
            let controlModel = ControlViewModel()
            ControlView(controlModel: controlModel)
        }
    }
}


