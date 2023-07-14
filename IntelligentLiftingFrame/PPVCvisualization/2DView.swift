//
//  2DView.swift
//  IntelligentLiftingFrame
//
//  Created by MAN DING on 14/7/23.
//

import SwiftUI

//range: +-50mm
struct SchematicView: View {
    @ObservedObject var data: MessageViewModel
    
    var body: some View {
        HStack(spacing: -313) {
            createDestReference()
            createTopView()
            createVerticalView().offset(x: -300, y: -30)
        }
    }
    
    func createTopView() -> some View {
        HStack {
            createPPVCForTopView()
            createYLabelForTopView()
            createXLabelForTopView()
            createYawLabelForTopView()
        }.offset(x: -393 + data.recvData.x * 1.5, y: -40 + data.recvData.y * (-1.5))
    }
    
    func createPPVCForTopView() -> some View {
        HStack {
            Rectangle()
                .fill(Color.gray)
                .opacity(0.5)
                .frame(width: 300, height: 110)
            Image(systemName: "control")
                .rotationEffect(.degrees(135))
                .font(Font.system(.title))
                .foregroundColor(.orange)
                .offset(x: -28.0, y: 50.0)
        }
        .rotationEffect(.degrees(data.recvData.yaw))
    }
    
    func createYLabelForTopView() -> some View {
        HStack {
            if data.recvData.y >= 0.0 {
                Image(systemName: "arrow.up")
                    .font(.system(size: 37))
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "arrow.down")
                    .font(.system(size: 37))
                    .foregroundColor(.blue)
            }
            Text("\(data.recvData.y, specifier: "%.0f")mm")
        }.offset(x: -67.0, y: 12.0)
    }
    
    func createXLabelForTopView() -> some View {
        VStack {
            if data.recvData.x >= 0.0 {
                Image(systemName: "arrow.left")
                    .font(.system(size: 37))
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "arrow.right")
                    .font(.system(size: 37))
                    .foregroundColor(.blue)
            }
            Text("\(data.recvData.x, specifier: "%.0f")mm")
        }.offset(x: -207.0, y: 65.0)
    }
    
    func createYawLabelForTopView() -> some View {
        HStack {
            if data.recvData.yaw >= 0.0 {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            } else  {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            Text("\(data.recvData.yaw, specifier: "%.0f")°")
        }.offset(x: -185.0, y: 55.0)
    }
    
    func createDestReference() -> some View {
        HStack(spacing: 252) {
            VStack(spacing: 77.5) {
                Image(systemName: "control")
                    .rotationEffect(.degrees(-45))
                    .font(Font.system(.largeTitle))
                Image(systemName: "control")
                    .rotationEffect(.degrees(-135))
                    .font(Font.system(.largeTitle))
            }
            VStack(spacing: 77.5) {
                Image(systemName: "control")
                    .rotationEffect(.degrees(45))
                    .font(Font.system(.largeTitle))
                Image(systemName: "control")
                    .rotationEffect(.degrees(135))
                    .font(Font.system(.largeTitle))
                    .foregroundColor(.orange)
            }
        }.position(x: 100, y: 110)
    }
    
    func createVerticalView() -> some View {
        HStack(spacing: -140) {
            Slider(value: $data.recvData.z, in: 0...1000) {
                Text("Vertical Distance")
            } minimumValueLabel: {
                Text("0").font(.title2).fontWeight(.thin).rotationEffect(.degrees(-90))
            } maximumValueLabel: {
                Text("1000").font(.title2).fontWeight(.thin).rotationEffect(.degrees(90))
            }
            .rotationEffect(.degrees(-90))
            .controlSize(.small)
            .disabled(true)
            Text("\(data.recvData.z, specifier: "%.0f") mm")
        }
        .frame(width: 220, height: 100)
    }
    
    
    func addAxis() -> some View {
        Axis().stroke(Color.green, lineWidth: 3)
    }
}

struct Axis: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 40, y: 40))
        path.addLine(to: CGPoint(x: 0, y: 40))
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}

