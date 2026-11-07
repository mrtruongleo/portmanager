import Foundation
import SwiftUI
import Combine

public enum StatusType {
    case info
    case success
    case error
}

public enum AppTab: String, CaseIterable {
    case inspector = "Port Inspector"
    case allPorts = "All Active Ports"
}

@MainActor
public final class PortManagerViewModel: ObservableObject {
    @Published public var portInput: String = ""
    @Published public var inspectedPort: Int? = nil
    @Published public var processes: [ProcessInfoItem] = []
    @Published public var isLoading: Bool = false
    @Published public var statusMessage: String? = nil
    @Published public var statusType: StatusType = .info
    
    // All listening ports list
    @Published public var activeTab: AppTab = .inspector
    @Published public var allListeningPorts: [ListeningPortItem] = []
    @Published public var isScanningAllPorts: Bool = false
    @Published public var filterAllPortsQuery: String = ""
    
    // Kill options
    @Published public var killTreeByDefault: Bool = true
    
    // Recent ports
    @Published public var recentPorts: [Int] = []
    private let recentPortsKey = "recentPorts_v1"
    
    private var toastTimer: Task<Void, Never>? = nil
    private let service = PortScannerService.shared
    
    public init() {
        loadRecentPorts()
    }
    
    public func loadRecentPorts() {
        recentPorts = UserDefaults.standard.array(forKey: recentPortsKey) as? [Int] ?? []
    }
    
    public func addRecentPort(_ port: Int) {
        var list = recentPorts.filter { $0 != port }
        list.insert(port, at: 0)
        if list.count > 6 {
            list = Array(list.prefix(6))
        }
        recentPorts = list
        UserDefaults.standard.set(list, forKey: recentPortsKey)
    }
    
    // Quick port presets
    public let presetPorts = [3000, 5173, 8000, 8080, 5432, 27017, 3306, 6379]
    
    // MARK: - Actions
    
    public func selectPreset(_ port: Int) {
        portInput = "\(port)"
        activeTab = .inspector
        inspectPort(port)
    }
    
    public func inspectCurrentInput() {
        let trimmed = portInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let port = Int(trimmed), port > 0, port <= 65535 else {
            showToast("Please enter a valid port number (1 - 65535)", type: .error)
            return
        }
        inspectPort(port)
    }
    
    public func inspectPort(_ port: Int) {
        inspectedPort = port
        addRecentPort(port)
        isLoading = true
        
        Task {
            let found = await service.findProcesses(onPort: port)
            self.processes = found
            self.isLoading = false
            
            if found.isEmpty {
                self.showToast("Port \(port) is FREE! No active processes listening.", type: .success)
            } else {
                self.showToast("Found \(found.count) process(es) on port \(port)", type: .info)
            }
        }
    }
    
    public func killSingle(process: ProcessInfoItem, killTree: Bool) {
        let targetPid = process.pid
        let res = killTree ? service.killProcessTree(pid: targetPid) : service.killProcess(pid: targetPid, force: true)
        
        switch res {
        case .success:
            NSSound(named: "Pop")?.play()
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            showToast("Killed \(process.name) (PID: \(targetPid))", type: .success)
        case .failure(let error):
            showToast("Error killing PID \(targetPid): \(error.localizedDescription)", type: .error)
        }
        
        // Refresh port after a brief pause
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let port = self.inspectedPort {
                self.inspectPort(port)
            }
        }
    }
    
    public func killAll() {
        guard let port = inspectedPort, !processes.isEmpty else { return }
        
        let pids = processes.map { $0.pid }
        let (killed, failed) = service.killAll(pids: pids, includeTrees: killTreeByDefault)
        
        if failed.isEmpty {
            NSSound(named: "Pop")?.play()
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            showToast("Terminated all \(killed.count) process(es) on port \(port)!", type: .success)
        } else {
            showToast("Killed \(killed.count) process(es), \(failed.count) failed", type: .error)
        }
        
        // Re-inspect to confirm port is clean
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.inspectPort(port)
        }
    }
    
    public func scanAllListeningPorts() {
        isScanningAllPorts = true
        Task {
            let items = await service.findListeningPorts()
            self.allListeningPorts = items
            self.isScanningAllPorts = false
        }
    }
    
    public var filteredAllPorts: [ListeningPortItem] {
        let q = filterAllPortsQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return allListeningPorts }
        return allListeningPorts.filter {
            "\($0.port)".contains(q) || $0.name.lowercased().contains(q) || $0.user.lowercased().contains(q)
        }
    }
    
    // MARK: - Toast Helpers
    
    public func showToast(_ message: String, type: StatusType = .info) {
        statusMessage = message
        statusType = type
        
        toastTimer?.cancel()
        toastTimer = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                self.statusMessage = nil
            }
        }
    }
    
    public func dismissToast() {
        statusMessage = nil
        toastTimer?.cancel()
    }
}

