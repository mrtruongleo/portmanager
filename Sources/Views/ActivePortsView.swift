import SwiftUI

public struct ActivePortsView: View {
    @ObservedObject var viewModel: PortManagerViewModel
    
    public init(viewModel: PortManagerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Filter & Refresh bar
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField("Filter by port, name or user...", text: $viewModel.filterAllPortsQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !viewModel.filterAllPortsQuery.isEmpty {
                        Button(action: { viewModel.filterAllPortsQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                
                Button(action: {
                    viewModel.scanAllListeningPorts()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(viewModel.isScanningAllPorts ? 360 : 0))
                            .animation(viewModel.isScanningAllPorts ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isScanningAllPorts)
                        Text("Refresh")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isScanningAllPorts)
            }
            
            // List of Listening Ports
            if viewModel.isScanningAllPorts && viewModel.allListeningPorts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Scanning active ports...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredAllPorts.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "network.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(viewModel.filterAllPortsQuery.isEmpty ? "No listening ports found." : "No matches for \"\(viewModel.filterAllPortsQuery)\"")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.filteredAllPorts) { item in
                            HStack(spacing: 10) {
                                // Port badge
                                Text(":\(item.port)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                    .frame(minWidth: 64, alignment: .center)
                                
                                // Details
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(item.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("PID \(item.pid)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("\(item.address) • \(item.user)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Inspect button
                                Button(action: {
                                    viewModel.selectPreset(item.port)
                                }) {
                                    HStack(spacing: 3) {
                                        Text("Inspect")
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                                
                                // Kill button
                                Button(action: {
                                    let res = PortScannerService.shared.killProcess(pid: item.pid, force: true)
                                    switch res {
                                    case .success:
                                        viewModel.showToast("Killed \(item.name) (PID \(item.pid))", type: .success)
                                    case .failure(let err):
                                        viewModel.showToast(err.localizedDescription, type: .error)
                                    }
                                    viewModel.scanAllListeningPorts()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.12))
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            if viewModel.allListeningPorts.isEmpty {
                viewModel.scanAllListeningPorts()
            }
        }
    }
}

