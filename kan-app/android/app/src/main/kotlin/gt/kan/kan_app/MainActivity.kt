package gt.kan.kan_app

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.os.Bundle
import android.view.WindowManager
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
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
                        "status" to status.toString(),
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
                        "ML Kit GenAI Prompt API returned status $status.",
                        mapOf("status" to status.toString()),
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
}
