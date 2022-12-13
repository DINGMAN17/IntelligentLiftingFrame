//
//  Client.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 28/11/22.
//

import Foundation
import Network

class Client {
    
    let connection: ClientConnection = initConnection()
    
    private static func initConnection() -> ClientConnection {
        let host = NWEndpoint.Host("127.0.0.1")
        let port = NWEndpoint.Port(rawValue: 8080)!
        let nwConnection = NWConnection(host: host, port: port, using: .tcp)
        return ClientConnection(nwConnection: nwConnection)
    }
    
    func start() {
        print("Client started")
        connection.didStopCallback = didStopCallback(error:)
        connection.start()
    }
    
    func stop() {
        connection.stop()
    }
    
    func send(data: Data) {
        connection.send(data: data)
    }
    
    func didStopCallback(error: Error?) {
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }
}
