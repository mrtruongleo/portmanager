import SwiftUI

public struct MainView: View {
    @StateObject private var viewModel = PortManagerViewModel()
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Header
            headerBar
            
            Divider()
            
            // MARK: - Main Content
            VStack(spacing: 12) {
                if viewModel.activeTab == .inspector {
                    inspectorView
                } else {
                    ActivePortsView(viewModel: viewModel)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // MARK: - Footer & Toast Bar
            footerBar
        }
        .frame(width: 460, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.accentColor)
            
            Text("Port Manager")
                .font(.system(size: 14, weight: .bold))
            
            Spacer()
            
            // Segmented Picker
            Picker("", selection: $viewModel.activeTab) {
                Text("Inspector").tag(AppTab.inspector)
                Text("Active Ports").tag(AppTab.allPorts)
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
            
            // Menu button for Quit
            Menu {
                Button("Refresh Current Port") {
                    if let port = viewModel.inspectedPort {
                        viewModel.inspectPort(port)
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Scan All Active Ports") {
                    viewModel.activeTab = .allPorts
                    viewModel.scanAllListeningPorts()
                }
                
                Divider()
                
                Button("Quit Port Manager") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - Inspector View
    private var inspectorView: some View {
        VStack(spacing: 10) {
            // Input Bar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13, weight: .semibold))
                    
                    TextField("Enter port (e.g. 3000, 8080)", text: $viewModel.portInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .focused($isInputFocused)
                        .onSubmit {
                            viewModel.inspectCurrentInput()
                        }
                    
                    if !viewModel.portInput.isEmpty {
                        Button(action: { viewModel.portInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                
                // "View" Button
                Button(action: {
                    viewModel.inspectCurrentInput()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                        Text("View")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(viewModel.portInput.isEmpty ? Color.gray.opacity(0.6) : Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.portInput.isEmpty || viewModel.isLoading)
            }
            
            // Quick Preset Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("Presets:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.presetPorts, id: \.self) { port in
                        Button(action: {
                            viewModel.selectPreset(port)
                        }) {
                            Text("\(port)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(viewModel.inspectedPort == port ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                                .foregroundColor(viewModel.inspectedPort == port ? .accentColor : .primary)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Results Section
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Inspecting port \(viewModel.inspectedPort ?? 0)...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.inspectedPort == nil {
                // Empty state: No port inspected yet
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Enter a Port & Click View")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Inspect active processes, related parent/child programs,\nand kill them with one click.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.processes.isEmpty {
                // Port is FREE!
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("Port \(viewModel.inspectedPort!) is Free")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("No active processes are currently listening on this port.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if let port = viewModel.inspectedPort {
                            viewModel.inspectPort(port)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Re-check Port")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Processes Found
                VStack(spacing: 8) {
                    // Actions Header
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Port \(viewModel.inspectedPort!): \(viewModel.processes.count) Process(es)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Kill All Button
                        Button(action: {
                            viewModel.killAll()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                Text("Kill All (\(viewModel.processes.count))")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    
                    // Process Cards List
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.processes) { proc in
                                ProcessCardView(process: proc) { killTree in
                                    viewModel.killSingle(process: proc, killTree: killTree)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
    
    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack(spacing: 8) {
            // Toast / Status Message
            if let msg = viewModel.statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: iconForToast(viewModel.statusType))
                        .foregroundColor(colorForToast(viewModel.statusType))
                        .font(.system(size: 11, weight: .bold))
                    Text(msg)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                .transition(.opacity)
            } else {
                Text("Ready")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private func iconForToast(_ type: StatusType) -> String {
        switch type {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func colorForToast(_ type: StatusType) -> Color {
        switch type {
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
}
