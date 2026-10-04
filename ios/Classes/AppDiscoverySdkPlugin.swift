import Flutter
import UIKit
import AppDiscoverySDK

/// Bridges Flutter calls to the AppDiscovery iOS SDK.
///
/// The offerwall host is a required setting: there is no default.
public class AppDiscoverySdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?

    // Configuration remembered from initSDK / setUserId, used when a call omits a value.
    private var activeHost = ""
    private var activeTrackerHost: String?
    private var activeAppId = ""
    private var activeSdkKey = ""
    private var activePlayerId = ""

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.appdiscoverysdk.flutter/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.appdiscoverysdk.flutter/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = AppDiscoverySdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "initSDK":
            activeHost = stringArg(args, "host")
            activeTrackerHost = nullableStringArg(args, "trackerHost")
            activeAppId = stringArg(args, "appId")
            activeSdkKey = stringArg(args, "sdkKey")
            activePlayerId = stringArg(args, "playerId")
            result(true)

        case "setUserId":
            activePlayerId = stringArg(args, "playerId")
            result(true)

        case "showOfferwall":
            DispatchQueue.main.async { [weak self] in
                self?.showOfferwall(args, result: result)
            }

        case "syncPendingRewards":
            syncPendingRewards(args, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Calls

    private func showOfferwall(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let topVC = getTopViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER",
                                message: "Unable to find a view controller to present the offerwall",
                                details: nil))
            return
        }

        let config = resolve(args)
        if config.appId.isEmpty || config.sdkKey.isEmpty {
            result(FlutterError(code: "INVALID_CONFIG", message: "appId and sdkKey must be provided", details: nil))
            return
        }

        do {
            let offerwall = try AppDiscovery.create(
                host: config.host,
                appId: config.appId,
                sdkKey: config.sdkKey,
                playerId: config.playerId,
                trackerHost: config.trackerHost
            )

            offerwall.onReward = { [weak self] reward in
                let data = AppDiscoverySdkPlugin.compact(reward)
                DispatchQueue.main.async {
                    self?.eventSink?(["event": "onReward", "data": data])
                }
            }

            offerwall.onClose = { [weak self] in
                DispatchQueue.main.async {
                    self?.eventSink?(["event": "onClose"])
                }
            }

            offerwall.launch(viewController: topVC)
            result(true)
        } catch let error as AppDiscoveryError {
            result(FlutterError(code: "INVALID_HOST", message: error.localizedDescription, details: nil))
        } catch {
            result(FlutterError(code: "LAUNCH_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func syncPendingRewards(_ args: [String: Any], result: @escaping FlutterResult) {
        let config = resolve(args)
        do {
            try AppDiscovery.syncPendingRewards(
                host: config.host,
                appId: config.appId,
                sdkKey: config.sdkKey,
                playerId: config.playerId,
                trackerHost: config.trackerHost
            ) { rewards in
                result(rewards.map { AppDiscoverySdkPlugin.compact($0) })
            }
        } catch let error as AppDiscoveryError {
            result(FlutterError(code: "INVALID_HOST", message: error.localizedDescription, details: nil))
        } catch {
            result(FlutterError(code: "SYNC_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Helpers

    private struct ResolvedConfig {
        let host: String
        let trackerHost: String?
        let appId: String
        let sdkKey: String
        let playerId: String
    }

    private func resolve(_ args: [String: Any]) -> ResolvedConfig {
        let hostArg = stringArg(args, "host")
        // The remembered tracker host belongs to the remembered host only.
        let trackerArg = nullableStringArg(args, "trackerHost") ?? (hostArg.isEmpty ? activeTrackerHost : nil)
        return ResolvedConfig(
            host: hostArg.isEmpty ? activeHost : hostArg,
            trackerHost: trackerArg,
            appId: firstNonEmpty(stringArg(args, "appId"), activeAppId),
            sdkKey: firstNonEmpty(stringArg(args, "sdkKey"), activeSdkKey),
            playerId: firstNonEmpty(stringArg(args, "playerId"), activePlayerId)
        )
    }

    private func stringArg(_ args: [String: Any], _ name: String) -> String {
        return (args[name] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func nullableStringArg(_ args: [String: Any], _ name: String) -> String? {
        let value = stringArg(args, name)
        return value.isEmpty ? nil : value
    }

    private func firstNonEmpty(_ preferred: String, _ fallback: String) -> String {
        return preferred.isEmpty ? fallback : preferred
    }

    /// Drops nil values so the payload can cross the platform channel.
    private static func compact(_ reward: [String: Any?]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (key, value) in reward {
            if let value = value {
                out[key] = value
            }
        }
        return out
    }

    private func getTopViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
        return top(of: root)
    }

    private func top(of viewController: UIViewController?) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return top(of: nav.visibleViewController) ?? nav
        }
        if let tab = viewController as? UITabBarController {
            return top(of: tab.selectedViewController) ?? tab
        }
        if let presented = viewController?.presentedViewController {
            return top(of: presented)
        }
        return viewController
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
