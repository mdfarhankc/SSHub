import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Smallest window the UI is designed for.
    self.contentMinSize = NSSize(width: 720, height: 560)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let secureChannel = FlutterMethodChannel(
      name: "sshub/secure_window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    secureChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setBlockScreenshots" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let enabled = (call.arguments as? Bool) ?? false
      // .none excludes the window from screenshots and screen recordings.
      self?.sharingType = enabled ? .none : .readOnly
      result(nil)
    }

    super.awakeFromNib()
  }
}
