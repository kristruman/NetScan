//
//  PingView.swift
//  NetScan
//
//  Created by Kris Truman on 10/7/2025.
//

import SwiftUI

struct PingView: View {
    @State private var host: String = "8.8.8.8"
    @State private var result: String = ""
    @State private var isPinging: Bool = false

    private let pingService = PingService()

    var body: some View {
        VStack(spacing: 20) {
            Text("📶 Ping Tool")
                .font(.largeTitle)
                .bold()

            TextField("Enter host (e.g. google.com)", text: $host)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                isPinging = true
                result = "Starting 5 pings..."
                pingService.ping(host: host, count: 5) { outputLines in
                    DispatchQueue.main.async {
                        result = outputLines.joined(separator: "\n")
                        isPinging = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                    Text(isPinging ? "Pinging..." : "Start Ping")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isPinging ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isPinging)
            .padding(.horizontal)

            ScrollView {
                Text(result)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Spacer()
        }
        .padding(.top)
    }
}
