//
//  BirdsEyeView.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 18/7/23.
//

//TODO: separate the UI and websocket. Take address from ControlView to initiate connection
import SwiftUI

struct BirdsEyeView: View {
    @State private var receivedImage: Image?
    
    var body: some View {
        VStack {
            if let image = receivedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600, height: 600)
            } else {
                Text("No image received yet.")
            }
        }
        .onAppear {
            connectWebSocket()
        }
    }
    
    func connectWebSocket() {
        //change URL address here
        guard let url = URL(string: "ws://192.168.1.14:8888") else {
            print("Invalid WebSocket URL")
            return
        }
        
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        let messageData = Data("begin".utf8)
        
        task.send(.data(messageData)) { error in
            if let error = error {
                print("WebSocket failed to send message: \(error)")
            } else {
                print("Message sent")
            }
        }
        
        func receiveLoop() {
            task.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        print(data)
                        DispatchQueue.main.async {
                            self.handleReceivedData(data)
                        }
                    case .string(let text):
                        print("Received text message: \(text)")
                        // Handle text messages if needed
                    @unknown default:
                        print("Unknown message type received.")
                    }
                    receiveLoop() // Continuously listen for new messages
                case .failure(let error):
                    print("WebSocket failed with error: \(error)")
                }
            }
        }
        receiveLoop()
    }
    
    func handleReceivedData(_ data: Data) {
        // Convert Data to SwiftUI Image and update the view
        if let uiImage = UIImage(data: data) {
            self.receivedImage = Image(uiImage: uiImage)
        }
    }
}
