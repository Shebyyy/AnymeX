import Flutter
import UIKit
import AVFoundation
import AVKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var pipChannel: FlutterMethodChannel?
  private var pipController: AVPictureInPictureController?
  private var pipPlayer: AVPlayer?
  private var pipPlayerLayer: AVPlayerLayer?
  private var pipPlayerView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    let thumbnailChannel = FlutterMethodChannel(name: "com.anymex.app/thumbnail", binaryMessenger: controller.binaryMessenger)
    cleanupOldThumbnails()

    thumbnailChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getVideoThumbnail" {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "videoPath is null", details: nil))
          return
        }
        self.extractThumbnail(videoPath: videoPath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let pipCh = FlutterMethodChannel(name: "com.ryan.anymex/pip", binaryMessenger: controller.binaryMessenger)
    self.pipChannel = pipCh

    pipCh.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isPipAvailable":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "isPipActive":
        result(self.pipController?.isPictureInPictureActive ?? false)
      case "enterPip":
        guard let args = call.arguments as? [String: Any] else {
          result(false)
          return
        }
        let urlString = args["url"] as? String ?? ""
        let headers = args["headers"] as? [String: String] ?? [:]
        self.startPip(urlString: urlString, headers: headers, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startPip(urlString: String, headers: [String: String], result: @escaping FlutterResult) {
    guard let url = URL(string: urlString), !urlString.isEmpty else {
      result(false)
      return
    }

    var asset: AVURLAsset
    if !headers.isEmpty {
      asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    } else {
      asset = AVURLAsset(url: url)
    }

    let playerItem = AVPlayerItem(asset: asset)
    if pipPlayer == nil {
      pipPlayer = AVPlayer(playerItem: playerItem)
    } else {
      pipPlayer?.replaceCurrentItem(with: playerItem)
    }

    if pipPlayerLayer == nil {
      pipPlayerLayer = AVPlayerLayer(player: pipPlayer)
      pipPlayerLayer?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
      pipPlayerLayer?.videoGravity = .resizeAspect
    }

    if pipPlayerView == nil {
      pipPlayerView = UIView(frame: CGRect(x: -1, y: -1, width: 1, height: 1))
      pipPlayerView?.layer.addSublayer(pipPlayerLayer!)
      pipPlayerView?.alpha = 0
      if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
        window.addSubview(pipPlayerView!)
      }
    }

    pipPlayer?.play()

    if pipController == nil {
      pipController = AVPictureInPictureController(playerLayer: pipPlayerLayer!)
    }

    pipController?.delegate = self

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.pipController?.startPictureInPicture()
      result(true)
    }
  }

  private func stopPip() {
    pipController?.stopPictureInPicture()
    pipPlayer?.pause()
    pipPlayerView?.removeFromSuperview()
    pipPlayer = nil
    pipPlayerLayer = nil
    pipPlayerView = nil
    pipController = nil
  }

  private func extractThumbnail(videoPath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let url = URL(fileURLWithPath: videoPath)
      let asset = AVAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.maximumSize = CGSize(width: 320, height: 240)

      let durationSeconds = CMTimeGetSeconds(asset.duration)
      let targetSeconds: Double
      if durationSeconds > 60 {
        targetSeconds = min(30.0, durationSeconds * 0.10)
      } else if durationSeconds > 10 {
        targetSeconds = min(5.0, durationSeconds * 0.10)
      } else if durationSeconds > 0 {
        targetSeconds = max(0.5, durationSeconds * 0.10)
      } else {
        targetSeconds = 1.0
      }

      let time = CMTime(seconds: targetSeconds, preferredTimescale: 60)
      do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        if let data = uiImage.jpegData(compressionQuality: 0.85) {
          let tempDir = NSTemporaryDirectory()
          let fileName = "thumb_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString).jpg"
          let filePath = (tempDir as NSString).appendingPathComponent(fileName)
          try data.write(to: URL(fileURLWithPath: filePath))

          DispatchQueue.main.async { result(filePath) }
          return
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "EXTRACTION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func cleanupOldThumbnails() {
    DispatchQueue.global(qos: .background).async {
      let tempDir = NSTemporaryDirectory()
      let fileManager = FileManager.default
      guard let files = try? fileManager.contentsOfDirectory(atPath: tempDir) else { return }
      let now = Date().timeIntervalSince1970
      for file in files where file.hasPrefix("thumb_") && file.hasSuffix(".jpg") {
        let path = (tempDir as NSString).appendingPathComponent(file)
        if let attrs = try? fileManager.attributesOfItem(atPath: path),
           let modDate = attrs[.modificationDate] as? Date,
           now - modDate.timeIntervalSince1970 > 86400 {
          try? fileManager.removeItem(atPath: path)
        }
      }
    }
  }
}

extension AppDelegate: AVPictureInPictureControllerDelegate {
  func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: true)
  }

  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: false)
    stopPip()
  }

  func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    pipChannel?.invokeMethod("onPipModeChanged", arguments: false)
  }

  func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    pipPlayer?.pause()
    pipChannel?.invokeMethod("onPipPause", arguments: nil)
  }
}
