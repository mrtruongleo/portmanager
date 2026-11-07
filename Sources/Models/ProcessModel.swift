import Foundation

public struct RelatedProcessInfo: Identifiable, Equatable, Sendable {
    public var id: String { "\(relationship.rawValue)-\(pid)" }
    public let pid: Int
    public let ppid: Int?
    public let name: String
    public let command: String
    public let user: String
    public let relationship: ProcessRelation
    
    public init(pid: Int, ppid: Int?, name: String, command: String, user: String, relationship: ProcessRelation) {
        self.pid = pid
        self.ppid = ppid
        self.name = name
        self.command = command
        self.user = user
        self.relationship = relationship
    }
}

public enum ProcessRelation: String, CaseIterable, Sendable {
    case parent = "Parent"
    case child = "Child Worker"
    case sibling = "Related"
}

public struct ProcessInfoItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let pid: Int
    public let ppid: Int?
    public let name: String
    public let user: String
    public let fd: String
    public let protocolType: String
    public let address: String
    public let state: String
    public let fullCommand: String
    public let cpu: String
    public let memory: String
    public let parentProcess: RelatedProcessInfo?
    public let childProcesses: [RelatedProcessInfo]
    
    public init(
        id: String,
        pid: Int,
        ppid: Int? = nil,
        name: String,
        user: String,
        fd: String = "",
        protocolType: String = "",
        address: String = "",
        state: String = "",
        fullCommand: String = "",
        cpu: String = "0.0%",
        memory: String = "0.0 MB",
        parentProcess: RelatedProcessInfo? = nil,
        childProcesses: [RelatedProcessInfo] = []
    ) {
        self.id = id
        self.pid = pid
        self.ppid = ppid
        self.name = name
        self.user = user
        self.fd = fd
        self.protocolType = protocolType
        self.address = address
        self.state = state
        self.fullCommand = fullCommand
        self.cpu = cpu
        self.memory = memory
        self.parentProcess = parentProcess
        self.childProcesses = childProcesses
    }
}

public struct ListeningPortItem: Identifiable, Equatable, Sendable {
    public var id: String { "\(port)-\(pid)-\(protocolType)" }
    public let port: Int
    public let pid: Int
    public let name: String
    public let user: String
    public let address: String
    public let protocolType: String
    
    public init(port: Int, pid: Int, name: String, user: String, address: String, protocolType: String) {
        self.port = port
        self.pid = pid
        self.name = name
        self.user = user
        self.address = address
        self.protocolType = protocolType
    }
}

