package gt.kan.kan_app

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.os.Bundle
import android.util.Base64
import android.view.WindowManager
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    companion object {
        private const val AUDIT_ARCHIVE_KEY_ALIAS = "zpk-audit-archive-aes-gcm-2026-05"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gt.kan.kan_app/mlkit_gemma",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> checkOnDeviceStatus(result)
                "generate" -> {
                    val prompt = call.argument<String>("prompt")?.trim()
                    if (prompt.isNullOrEmpty()) {
                        result.error("INVALID_PROMPT", "Prompt must not be empty.", null)
                    } else {
                        generateOnDevice(prompt, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gt.kan.kan_app/identity_keystore",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "signHmacSha256" -> {
                    val keyId = call.argument<String>("keyId")?.trim()
                    val payload = call.argument<String>("payload") ?: ""
                    if (keyId.isNullOrEmpty() || payload.isEmpty()) {
                        result.error(
                            "INVALID_SIGNING_INPUT",
                            "keyId and payload are required.",
                            null,
                        )
                    } else {
                        signIdentityPayload(keyId, payload, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gt.kan.kan_app/audit_archive",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "append" -> {
                    val recordJson = call.argument<String>("recordJson") ?: ""
                    val recordHash = call.argument<String>("recordHash")?.trim() ?: ""
                    if (recordJson.isEmpty() || recordHash.length < 16) {
                        result.error(
                            "INVALID_AUDIT_RECORD",
                            "recordJson and recordHash are required.",
                            null,
                        )
                    } else {
                        appendAuditRecord(recordJson, recordHash, result)
                    }
                }
                "clear" -> clearAuditArchive(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        scope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun checkOnDeviceStatus(result: MethodChannel.Result) {
        scope.launch {
            try {
                val generativeModel = Generation.getClient()
                val status = generativeModel.checkStatus()
                result.success(
                    mapOf(
                        "status" to statusName(status),
                        "model" to "mlkit-genai-prompt-aicore",
                    ),
                )
            } catch (error: Throwable) {
                result.error(
                    "MLKIT_GEMMA_STATUS_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun generateOnDevice(prompt: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                val generativeModel = Generation.getClient()
                val status = generativeModel.checkStatus()

                when (status) {
                    FeatureStatus.UNAVAILABLE -> result.error(
                        "UNAVAILABLE",
                        "ML Kit GenAI Prompt API is unavailable on this device.",
                        mapOf("status" to "UNAVAILABLE"),
                    )
                    FeatureStatus.DOWNLOADABLE -> result.error(
                        "DOWNLOADABLE",
                        "The on-device GenAI model is supported but not downloaded yet.",
                        mapOf("status" to "DOWNLOADABLE"),
                    )
                    FeatureStatus.DOWNLOADING -> result.error(
                        "DOWNLOADING",
                        "The on-device GenAI model is still downloading.",
                        mapOf("status" to "DOWNLOADING"),
                    )
                    FeatureStatus.AVAILABLE -> {
                        val response = generativeModel.generateContent(prompt)
                        val text = response.candidates.firstOrNull()?.text?.trim().orEmpty()
                        if (text.isEmpty()) {
                            result.error(
                                "EMPTY_RESPONSE",
                                "ML Kit GenAI Prompt API returned no candidate text.",
                                mapOf("status" to "AVAILABLE"),
                            )
                        } else {
                            result.success(
                                mapOf(
                                    "text" to text,
                                    "status" to "AVAILABLE",
                                    "model" to "mlkit-genai-prompt-aicore",
                                ),
                            )
                        }
                    }
                    else -> result.error(
                        "UNKNOWN_STATUS",
                        "ML Kit GenAI Prompt API returned status ${statusName(status)}.",
                        mapOf("status" to statusName(status)),
                    )
                }
            } catch (error: Throwable) {
                result.error(
                    "MLKIT_GEMMA_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun signIdentityPayload(
        keyId: String,
        payload: String,
        result: MethodChannel.Result,
    ) {
        try {
            val key = getOrCreateHmacKey(keyId)
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(key)
            val proof = mac.doFinal(payload.toByteArray(Charsets.UTF_8)).toHex()
            result.success(
                mapOf(
                    "proofValue" to proof,
                    "keyStore" to "android-keystore",
                    "proofSuite" to "HmacSha256Signature2026",
                ),
            )
        } catch (error: Throwable) {
            result.error(
                "KEYSTORE_SIGN_ERROR",
                error.message ?: error.javaClass.simpleName,
                mapOf("type" to error.javaClass.name),
            )
        }
    }

    private fun appendAuditRecord(
        recordJson: String,
        recordHash: String,
        result: MethodChannel.Result,
    ) {
        try {
            val archiveDir = File(filesDir, "zpk-audit-archive")
            if (!archiveDir.exists() && !archiveDir.mkdirs()) {
                result.error(
                    "AUDIT_ARCHIVE_ERROR",
                    "Could not create audit archive directory.",
                    null,
                )
                return
            }
            val safeName = recordHash.take(64).replace(Regex("[^a-fA-F0-9]"), "")
            val sealedRecord = encryptAuditRecord(recordJson)
            val file = File(archiveDir, "$safeName.sealed.json")
            file.writeText(sealedRecord, Charsets.UTF_8)
            val recordCount = archiveDir.listFiles { candidate ->
                candidate.isFile && candidate.name.endsWith(".sealed.json")
            }?.size ?: 0

            result.success(
                mapOf(
                    "location" to "app-internal:zpk-audit-archive/${file.name}",
                    "recordCount" to recordCount,
                    "cryptoSuite" to "AES-GCM-256",
                    "keyStore" to "android-keystore",
                ),
            )
        } catch (error: Throwable) {
            result.error(
                "AUDIT_ARCHIVE_ERROR",
                error.message ?: error.javaClass.simpleName,
                mapOf("type" to error.javaClass.name),
            )
        }
    }

    private fun clearAuditArchive(result: MethodChannel.Result) {
        try {
            val archiveDir = File(filesDir, "zpk-audit-archive")
            var deletedCount = 0
            archiveDir.listFiles { candidate ->
                candidate.isFile &&
                    (candidate.name.endsWith(".json") || candidate.name.endsWith(".sealed.json"))
            }?.forEach { file ->
                if (file.delete()) {
                    deletedCount += 1
                }
            }

            result.success(
                mapOf(
                    "location" to "app-internal:zpk-audit-archive",
                    "deletedCount" to deletedCount,
                ),
            )
        } catch (error: Throwable) {
            result.error(
                "AUDIT_ARCHIVE_CLEAR_ERROR",
                error.message ?: error.javaClass.simpleName,
                mapOf("type" to error.javaClass.name),
            )
        }
    }

    private fun encryptAuditRecord(recordJson: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateAuditArchiveKey())
        val ciphertext = cipher.doFinal(recordJson.toByteArray(Charsets.UTF_8))
        val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        val encryptedPayload = Base64.encodeToString(ciphertext, Base64.NO_WRAP)
        return """{"version":1,"cipherSuite":"AES-GCM-256","keyAlias":"$AUDIT_ARCHIVE_KEY_ALIAS","iv":"$iv","ciphertext":"$encryptedPayload"}"""
    }

    private fun getOrCreateAuditArchiveKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyStore.getKey(AUDIT_ARCHIVE_KEY_ALIAS, null)?.let { return it as SecretKey }

        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        val spec = KeyGenParameterSpec.Builder(
            AUDIT_ARCHIVE_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        generator.init(spec)
        return generator.generateKey()
    }

    private fun getOrCreateHmacKey(keyId: String): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyStore.getKey(keyId, null)?.let { return it as SecretKey }

        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_HMAC_SHA256,
            "AndroidKeyStore",
        )
        val spec = KeyGenParameterSpec.Builder(
            keyId,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setKeySize(256)
            .build()
        generator.init(spec)
        return generator.generateKey()
    }

    private fun ByteArray.toHex(): String =
        joinToString(separator = "") { byte -> "%02x".format(byte) }

    private fun statusName(status: Int): String =
        when (status) {
            FeatureStatus.UNAVAILABLE -> "UNAVAILABLE"
            FeatureStatus.DOWNLOADABLE -> "DOWNLOADABLE"
            FeatureStatus.DOWNLOADING -> "DOWNLOADING"
            FeatureStatus.AVAILABLE -> "AVAILABLE"
            else -> "UNKNOWN_$status"
        }
}
