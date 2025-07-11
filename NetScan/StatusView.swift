//
//  StatusView.swift
//  NetScan
//
//  Created by Kris Truman on 10/7/2025.
//

import SwiftUI
import Network
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import Darwin

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
}

struct StatusView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let locationManager = LocationManager()

    @State private var connectionType: String = "Checking..."
    @State private var publicIP: String = "Fetching..."
    @State private var localIP: String = "Loading..."
    @State private var ssid: String = "Loading..."

    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("📡 NetScan")
                    .font(.largeTitle)
                    .bold()

                Group {
                    labeledBlock(title: "Connection Type", value: connectionType, icon: "wifi.router")
                    labeledBlock(title: "Public IP Address", value: publicIP, icon: "network")
                    labeledBlock(title: "Local IP Address", value: localIP, icon: "desktopcomputer")
                    labeledBlock(title: "WiFi SSID", value: ssid, icon: "dot.radiowaves.left.and.right")
                }

                Spacer()
            }
            .padding()
        }
        // 👇 Move onAppear here
        .onAppear {
            startNetworkMonitoring()
            fetchPublicIP()
            localIP = getLocalIPAddress()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ssid = fetchSSID()
            }
        }
        // 👇 Gradient background stays here
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                                   ? [Color(.systemGray6), Color(.black)]
                                   : [Color(.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    func labeledBlock(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .monospaced()
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        connectionType = "WiFi"
                    } else if path.usesInterfaceType(.cellular) {
                        connectionType = "Cellular"
                    } else {
                        connectionType = "Connected (Other)"
                    }
                } else {
                    connectionType = "Offline"
                }
            }
        }
        monitor.start(queue: queue)
    }

    func fetchPublicIP() {
        guard let url = URL(string: "https://api.ipify.org?format=text") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    publicIP = ip
                }
            } else {
                DispatchQueue.main.async {
                    publicIP = "Unavailable"
                }
            }
        }.resume()
    }

    func getLocalIPAddress() -> String {
        var address: String = "Unavailable"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }

    func fetchSSID() -> String {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return "Unavailable" }
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary?,
               let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        return "Unavailable"
    }
}
