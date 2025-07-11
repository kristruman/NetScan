//
//  PingService.swift
//  NetScan
//
//  Created by Kris Truman on 10/7/2025.
//

import Foundation

class PingService: NSObject {
    private var simplePing: SimplePing?
    private var completion: (([String]) -> Void)?
    private var startTimes: [Date] = []
    private var results: [String] = []
    private var currentPing = 0
    private var maxPings = 5
    private var responseTimes: [Double] = []
    private var timer: Timer?

    func ping(host: String, count: Int = 5, completion: @escaping ([String]) -> Void) {
        self.completion = completion
        self.maxPings = count
        self.results = []
        self.responseTimes = []
        self.currentPing = 0
        self.simplePing = SimplePing(hostName: host)
        self.simplePing?.delegate = self
        DispatchQueue.main.async {
            self.simplePing?.start()
        }
    }

    private func sendPing() {
        guard currentPing < maxPings else {
            finish()
            return
        }

        currentPing += 1
        startTimes.append(Date())

        simplePing?.send(with: nil)

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.results.append("Ping \(self.currentPing): Timeout")
            self.sendPing()
        }
    }

    private func finish() {
        simplePing?.stop()
        simplePing = nil
        timer?.invalidate()

        if !responseTimes.isEmpty {
            let avg = responseTimes.reduce(0, +) / Double(responseTimes.count)
            results.append(String(format: "Average latency: %.2f ms", avg * 1000))
        }

        completion?(results)
    }
}

extension PingService: SimplePingDelegate {

    @objc func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        print("✅ Ping started to \(pinger.hostName ?? "unknown host")")
        sendPing()
    }

    @objc func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        print("❌ Ping failed: \(error.localizedDescription)")
        results.append("Ping failed: \(error.localizedDescription)")
        finish()
    }

    @objc func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data) {
        timer?.invalidate()
        guard currentPing <= startTimes.count else { return }

        let latency = Date().timeIntervalSince(startTimes[currentPing - 1])
        responseTimes.append(latency)

        let result = String(format: "Ping \(currentPing): %.2f ms", latency * 1000)
        print("✅ \(result)")
        results.append(result)

        sendPing()
    }

    @objc func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data?, error: Error) {
        timer?.invalidate()
        print("❌ Failed to send ping \(currentPing): \(error.localizedDescription)")
        results.append("Ping \(currentPing): Send failed")
        sendPing()
    }
}
