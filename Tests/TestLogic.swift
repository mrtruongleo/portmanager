import Foundation

@main
struct TestRunner {
    static func main() async {
        print("🧪 Testing PortScannerService logic...")
        
        // 1. Start a dummy python server on port 9993
        let port = 9993
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/Users/leo/.pyenv/versions/3.12.9/bin/python3")
        proc.arguments = ["-m", "http.server", "\(port)"]
        try? proc.run()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("🔍 Inspecting port \(port)...")
        let service = PortScannerService.shared
        let results = await service.findProcesses(onPort: port)
        
        print("Found \(results.count) process(es):")
        for item in results {
            print(" - PID: \(item.pid), Name: \(item.name), User: \(item.user), State: \(item.state)")
            print("   Command: \(item.fullCommand)")
            if let parent = item.parentProcess {
                print("   Parent: \(parent.name) (PID: \(parent.pid))")
            }
            if !item.childProcesses.isEmpty {
                print("   Children: \(item.childProcesses.count)")
            }
        }
        
        assert(!results.isEmpty, "Should find at least 1 process on port \(port)")
        
        // 2. Test Kill
        print("⚡ Testing Kill All on port \(port)...")
        let pids = results.map { $0.pid }
        let (killed, failed) = service.killAll(pids: pids)
        print("Killed: \(killed), Failed: \(failed)")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        let recheck = await service.findProcesses(onPort: port)
        print("Recheck processes count: \(recheck.count)")
        assert(recheck.isEmpty, "Port \(port) should now be free")
        
        print("🎉 All service logic tests PASSED successfully!")
    }
}

