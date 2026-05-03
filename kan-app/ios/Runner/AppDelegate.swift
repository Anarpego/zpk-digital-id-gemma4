import Flutter
import CryptoKit
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let identityKeyService = "gt.kan.kan_app.identity_keystore"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ZpkIdentityKeystorePlugin")
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "gt.kan.kan_app/identity_keystore",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "signHmacSha256" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let keyId = args["keyId"] as? String,
        let payload = args["payload"] as? String,
        !keyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !payload.isEmpty
      else {
        result(
          FlutterError(
            code: "INVALID_SIGNING_INPUT",
            message: "keyId and payload are required.",
            details: nil
          )
        )
        return
      }
      do {
        let proof = try self?.signHmacSha256(keyId: keyId, payload: payload) ?? ""
        result([
          "proofValue": proof,
          "keyStore": "ios-keychain",
          "proofSuite": "HmacSha256Signature2026",
        ])
      } catch {
        result(
          FlutterError(
            code: "KEYSTORE_SIGN_ERROR",
            message: error.localizedDescription,
            details: ["type": String(describing: type(of: error))]
          )
        )
      }
    }
  }

  private func signHmacSha256(keyId: String, payload: String) throws -> String {
    let keyData = try getOrCreateIdentityKey(keyId: keyId)
    let key = SymmetricKey(data: keyData)
    let signature = HMAC<SHA256>.authenticationCode(
      for: Data(payload.utf8),
      using: key
    )
    return signature.map { String(format: "%02x", $0) }.joined()
  }

  private func getOrCreateIdentityKey(keyId: String) throws -> Data {
    let account = "zpk-ios-identity-\(keyId)"
    let lookup: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identityKeyService,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
    ]
    var item: CFTypeRef?
    let lookupStatus = SecItemCopyMatching(lookup as CFDictionary, &item)
    if lookupStatus == errSecSuccess, let data = item as? Data {
      return data
    }
    guard lookupStatus == errSecItemNotFound else {
      throw KeychainError(status: lookupStatus)
    }

    var bytes = [UInt8](repeating: 0, count: 32)
    let randomStatus = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    guard randomStatus == errSecSuccess else {
      throw KeychainError(status: randomStatus)
    }
    let data = Data(bytes)
    let add: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: identityKeyService,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData as String: data,
    ]
    let addStatus = SecItemAdd(add as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw KeychainError(status: addStatus)
    }
    return data
  }
}

private struct KeychainError: LocalizedError {
  let status: OSStatus

  var errorDescription: String? {
    "Keychain operation failed with status \(status)."
  }
}
