import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    NSLog(">_>")
  }

  func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
    true
  }
}
