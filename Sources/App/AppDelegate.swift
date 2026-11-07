import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover = NSPopover()
    private var eventMonitor: Any?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from quitting when windows close and disable automatic termination
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("Port Manager status bar utility must remain active")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        // Setup Status Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            let image = NSImage(systemSymbolName: "network", accessibilityDescription: "Port Manager")?.withSymbolConfiguration(config)
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Port Manager - Click to inspect or kill ports"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup Popover
        let hostingController = NSHostingController(rootView: MainView())
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 460, height: 580)
        popover.behavior = .transient
        popover.animates = true
        
        // Global monitor to close popover when clicked outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            if self.popover.isShown {
                self.closePopover(sender: nil)
            }
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Right click shows a quick menu
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }
    
    @objc public func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    public func showPopover(sender: Any?) {
        guard let button = statusItem?.button else { return }
        
        // Bring app to foreground
        NSApp.activate(ignoringOtherApps: true)
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Make window key so keyboard shortcuts and text input work immediately
        if let window = popover.contentViewController?.view.window {
            window.makeKey()
        }
    }
    
    public func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Port Manager", action: #selector(togglePopover(_:)), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Port Manager", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // clear menu so left-click continues to toggle popover
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
