import SwiftUI

public struct ProcessCardView: View {
    public let process: ProcessInfoItem
    public let onKill: (_ killTree: Bool) -> Void
    
    @State private var isShowingCommand = false
    @State private var isCopied = false
    
    public init(process: ProcessInfoItem, onKill: @escaping (_ killTree: Bool) -> Void) {
        self.process = process
        self.onKill = onKill
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: iconForProcess(process.name))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(process.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("PID: \(process.pid)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text("User: \(process.user) • \(process.address)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Kill Button
                Button(action: {
                    onKill(false)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Kill")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Stats / Info Pills
            HStack(spacing: 6) {
                badge(title: "CPU", value: process.cpu, color: .orange)
                badge(title: "MEM", value: process.memory, color: .purple)
                badge(title: "PROTO", value: process.protocolType, color: .blue)
                badge(title: "STATE", value: process.state.isEmpty ? "LISTEN" : process.state, color: .red)
                
                Spacer()
                
                // Copy command button
                Button(action: copyCommand) {
                    HStack(spacing: 3) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy Command")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            
            // Full Command (Expandable / Preview)
            VStack(alignment: .leading, spacing: 4) {
                Text(process.fullCommand)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(isShowingCommand ? nil : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                    .cornerRadius(4)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingCommand.toggle()
                        }
                    }
            }
            
            // Related Process / Parent Process Section
            if let parent = process.parentProcess {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.left.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Parent / Launcher:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(parent.name) (PID: \(parent.pid))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            onKill(true) // Kill tree
                        }) {
                            Text("Kill Tree")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(parent.command)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(8)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Child Worker Processes Section
            if !process.childProcesses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.right.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.teal)
                        Text("Child Processes (\(process.childProcesses.count)):")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    ForEach(process.childProcesses) { child in
                        HStack(spacing: 6) {
                            Text("• \(child.name)")
                                .font(.system(size: 10, weight: .medium))
                            Text("PID: \(child.pid)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(8)
                .background(Color.teal.opacity(0.06))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
    
    private func badge(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .cornerRadius(4)
    }
    
    private func iconForProcess(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("node") || n.contains("bun") || n.contains("deno") {
            return "chevron.left.forwardslash.chevron.right"
        } else if n.contains("python") {
            return "chevron.right.2"
        } else if n.contains("docker") || n.contains("container") {
            return "shippingbox.fill"
        } else if n.contains("postgres") || n.contains("sql") || n.contains("mongo") || n.contains("redis") {
            return "cylinder.split.1x2.fill"
        } else if n.contains("java") {
            return "cup.and.saucer.fill"
        } else if n.contains("go") || n.contains("rust") || n.contains("cargo") {
            return "gearshape.2.fill"
        } else {
            return "terminal.fill"
        }
    }
    
    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(process.fullCommand, forType: .string)
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

