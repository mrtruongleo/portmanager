import Foundation
import Darwin

public final class PortScannerService: Sendable {
    public static let shared = PortScannerService()
    
    private init() {}
    
    // MARK: - Execute Helper
    @discardableResult
    public func executeCommand(_ executable: String, arguments: [String]) -> (output: String, error: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outData, encoding: .utf8) ?? ""
            let error = String(data: errData, encoding: .utf8) ?? ""
            return (output, error, process.terminationStatus)
        } catch {
            return ("", error.localizedDescription, -1)
        }
    }
    
    // MARK: - Inspect Port
    public func findProcesses(onPort port: Int) async -> [ProcessInfoItem] {
        return await Task.detached(priority: .userInitiated) { [self] in
            // lsof -nP -i :<port>
            let (lsofOutput, _, _) = self.executeCommand("/usr/sbin/lsof", arguments: ["-nP", "-i", ":\(port)"])
            let lines = lsofOutput.split(separator: "\n").map(String.init)
            
            guard lines.count > 1 else {
                return []
            }
            
            // Collect entries grouped by PID
            struct RawEntry {
                let command: String
                let pid: Int
                let user: String
                let fd: String
                let type: String
                let address: String
                let state: String
            }
            
            var rawEntries: [RawEntry] = []
            
            for line in lines.dropFirst() {
                let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                // lsof columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME [STATE]
                guard parts.count >= 9, let pid = Int(parts[1]) else { continue }
                
                let command = parts[0]
                let user = parts[2]
                let fd = parts[3]
                let type = parts[4]
                
                // Name usually starts at index 8. State might be in (LISTEN) at end
                let remainingParts = Array(parts[8...])
                let nameJoined = remainingParts.joined(separator: " ")
                
                var state = ""
                var address = nameJoined
                if let openParen = nameJoined.range(of: "("), let closeParen = nameJoined.range(of: ")") {
                    state = String(nameJoined[openParen.upperBound..<closeParen.lowerBound])
                    address = String(nameJoined[..<openParen.lowerBound]).trimmingCharacters(in: .whitespaces)
                }
                
                rawEntries.append(RawEntry(
                    command: command,
                    pid: pid,
                    user: user,
                    fd: fd,
                    type: type,
                    address: address,
                    state: state
                ))
            }
            
            // Group by PID
            var groupedByPid: [Int: [RawEntry]] = [:]
            for entry in rawEntries {
                groupedByPid[entry.pid, default: []].append(entry)
            }
            
            var results: [ProcessInfoItem] = []
            
            for (pid, entries) in groupedByPid {
                guard let first = entries.first else { continue }
                
                // Fetch deep process details via ps
                let psInfo = self.fetchProcessDetails(pid: pid)
                
                // Fetch Parent Process
                var parentInfo: RelatedProcessInfo? = nil
                if let ppid = psInfo.ppid, ppid > 1 {
                    parentInfo = self.fetchRelatedProcess(pid: ppid, relationship: .parent)
                }
                
                // Fetch Child Processes
                let childPids = self.fetchChildPids(for: pid)
                let childProcesses: [RelatedProcessInfo] = childPids.compactMap { childPid in
                    self.fetchRelatedProcess(pid: childPid, relationship: .child)
                }
                
                // Combine addresses and states
                let addresses = Array(Set(entries.map { $0.address })).joined(separator: ", ")
                let states = Array(Set(entries.map { $0.state.isEmpty ? "LISTEN" : $0.state })).joined(separator: ", ")
                let types = Array(Set(entries.map { $0.type })).joined(separator: ", ")
                
                let item = ProcessInfoItem(
                    id: "\(pid)-\(port)",
                    pid: pid,
                    ppid: psInfo.ppid,
                    name: psInfo.name.isEmpty ? first.command : psInfo.name,
                    user: psInfo.user.isEmpty ? first.user : psInfo.user,
                    fd: entries.map { $0.fd }.joined(separator: ", "),
                    protocolType: types,
                    address: addresses,
                    state: states,
                    fullCommand: psInfo.fullCommand.isEmpty ? first.command : psInfo.fullCommand,
                    cpu: psInfo.cpu,
                    memory: psInfo.memory,
                    parentProcess: parentInfo,
                    childProcesses: childProcesses
                )
                
                results.append(item)
            }
            
            // Sort by PID ascending
            return results.sorted { $0.pid < $1.pid }
        }.value
    }
    
    // MARK: - Process Details via `ps`
    private struct PsDetails {
        let ppid: Int?
        let user: String
        let cpu: String
        let memory: String
        let fullCommand: String
        let name: String
    }
    
    private func extractBinaryName(from fullArgs: String, fallback: String) -> String {
        let trimmed = fullArgs.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return fallback }
        let firstToken = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        let name = URL(fileURLWithPath: firstToken).lastPathComponent
        return name.isEmpty ? fallback : name
    }
    
    private func fetchProcessDetails(pid: Int) -> PsDetails {
        let (output, _, _) = executeCommand("/bin/ps", arguments: ["-p", "\(pid)", "-ww", "-o", "pid,ppid,user,%cpu,%mem,args"])
        let lines = output.split(separator: "\n").map(String.init)
        guard lines.count > 1 else {
            return PsDetails(ppid: nil, user: "", cpu: "0.0%", memory: "0.0 MB", fullCommand: "", name: "")
        }
        
        let row = lines[1].trimmingCharacters(in: .whitespaces)
        let parts = row.split(maxSplits: 5, whereSeparator: { $0.isWhitespace }).map(String.init)
        
        guard parts.count >= 5 else {
            return PsDetails(ppid: nil, user: "", cpu: "0.0%", memory: "0.0 MB", fullCommand: "", name: "")
        }
        
        let ppid = Int(parts[1])
        let user = parts[2]
        let cpu = "\(parts[3])%"
        let mem = "\(parts[4])%"
        let args = parts.count > 5 ? parts[5] : ""
        let binaryName = extractBinaryName(from: args, fallback: "")
        
        return PsDetails(
            ppid: ppid,
            user: user,
            cpu: cpu,
            memory: mem,
            fullCommand: args,
            name: binaryName
        )
    }
    
    // MARK: - Fetch Related Process
    private func fetchRelatedProcess(pid: Int, relationship: ProcessRelation) -> RelatedProcessInfo? {
        let (output, _, _) = executeCommand("/bin/ps", arguments: ["-p", "\(pid)", "-ww", "-o", "pid,ppid,user,args"])
        let lines = output.split(separator: "\n").map(String.init)
        guard lines.count > 1 else { return nil }
        
        let row = lines[1].trimmingCharacters(in: .whitespaces)
        let parts = row.split(maxSplits: 3, whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count >= 3 else { return nil }
        
        let ppid = Int(parts[1])
        let user = parts[2]
        let args = parts.count > 3 ? parts[3] : ""
        let name = extractBinaryName(from: args, fallback: "process")
        
        return RelatedProcessInfo(
            pid: pid,
            ppid: ppid,
            name: name,
            command: args,
            user: user,
            relationship: relationship
        )
    }
    
    // MARK: - Child PIDs
    private func fetchChildPids(for pid: Int) -> [Int] {
        let (output, _, _) = executeCommand("/usr/bin/pgrep", arguments: ["-P", "\(pid)"])
        let lines = output.split(separator: "\n").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return lines
    }
    
    // MARK: - Kill Process
    public enum KillError: LocalizedError {
        case processNotFound
        case permissionDenied
        case failed(String)
        
        public var errorDescription: String? {
            switch self {
            case .processNotFound:
                return "Process was already terminated or not found."
            case .permissionDenied:
                return "Permission denied. Root privileges required to terminate this process."
            case .failed(let msg):
                return "Failed to kill process: \(msg)"
            }
        }
    }
    
    public func killProcess(pid: Int, force: Bool = true) -> Result<Void, KillError> {
        let signal = force ? SIGKILL : SIGTERM
        let res = Darwin.kill(pid_t(pid), signal)
        
        if res == 0 {
            return .success(())
        }
        
        let err = errno
        if err == ESRCH {
            // Already gone
            return .success(())
        } else if err == EPERM {
            // Try administrator privileges via osascript
            let appleScript = "do shell script \"kill -9 \(pid)\" with administrator privileges"
            let (_, _, code) = executeCommand("/usr/bin/osascript", arguments: ["-e", appleScript])
            if code == 0 {
                return .success(())
            } else {
                return .failure(.permissionDenied)
            }
        } else {
            return .failure(.failed("errno \(err)"))
        }
    }
    
    public func killProcessTree(pid: Int) -> Result<Void, KillError> {
        // Collect all descendant PIDs
        var allPidsToKill: [Int] = [pid]
        var queue = [pid]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let children = fetchChildPids(for: current)
            for child in children {
                if !allPidsToKill.contains(child) {
                    allPidsToKill.append(child)
                    queue.append(child)
                }
            }
        }
        
        // Kill from leaves up
        for targetPid in allPidsToKill.reversed() {
            _ = killProcess(pid: targetPid, force: true)
        }
        
        return .success(())
    }
    
    public func killAll(pids: [Int], includeTrees: Bool = true) -> (killed: [Int], failed: [Int]) {
        var killed: [Int] = []
        var failed: [Int] = []
        
        for pid in pids {
            let res = includeTrees ? killProcessTree(pid: pid) : killProcess(pid: pid, force: true)
            switch res {
            case .success:
                killed.append(pid)
            case .failure:
                failed.append(pid)
            }
        }
        
        return (killed, failed)
    }
    
    // MARK: - Scan All Listening Ports
    public func findListeningPorts() async -> [ListeningPortItem] {
        return await Task.detached(priority: .userInitiated) { [self] in
            let (output, _, _) = self.executeCommand("/usr/sbin/lsof", arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"])
            let lines = output.split(separator: "\n").map(String.init)
            
            guard lines.count > 1 else { return [] }
            
            var items: [ListeningPortItem] = []
            var seen = Set<String>()
            
            for line in lines.dropFirst() {
                let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                guard parts.count >= 9, let pid = Int(parts[1]) else { continue }
                
                let command = parts[0]
                let user = parts[2]
                let type = parts[4]
                
                let remaining = parts[8...].joined(separator: " ")
                // address like *:3000 (LISTEN) or 127.0.0.1:8080 (LISTEN)
                var address = remaining
                if let openParen = remaining.range(of: "(") {
                    address = String(remaining[..<openParen.lowerBound]).trimmingCharacters(in: .whitespaces)
                }
                
                // Extract port number after the last colon
                guard let lastColon = address.lastIndex(of: ":") else { continue }
                let portStr = String(address[address.index(after: lastColon)...])
                guard let port = Int(portStr) else { continue }
                
                let key = "\(port)-\(pid)"
                if !seen.contains(key) {
                    seen.insert(key)
                    items.append(ListeningPortItem(
                        port: port,
                        pid: pid,
                        name: command,
                        user: user,
                        address: address,
                        protocolType: type
                    ))
                }
            }
            
            // Sort by port ascending
            return items.sorted { $0.port < $1.port }
        }.value
    }
}
