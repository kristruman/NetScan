//
//  ContentView.swift
//  NetScan
//
//  Created by Kris Truman on 10/7/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StatusView()
                .tabItem {
                    Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                }

            PingView()
                .tabItem {
                    Label("Ping", systemImage: "bolt.horizontal")
                }

            DNSView()
                .tabItem {
                    Label("DNS", systemImage: "globe")
                }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
