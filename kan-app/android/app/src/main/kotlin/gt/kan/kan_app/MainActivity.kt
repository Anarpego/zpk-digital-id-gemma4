package gt.kan.kan_app

import android.app.Activity
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.view.WindowManager
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.SamplerConfig
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URL
import java.security.MessageDigest
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var deviceAuthResult: MethodChannel.Result? = null
    private val litertLock = Any()
    private var litertEngine: Engine? = null
    private var litertEngineModelPath: String? = null

    companion object {
        private const val AUDIT_ARCHIVE_KEY_ALIAS = "zpk-audit-archive-aes-gcm-2026-05"
        private const val DEVICE_AUTH_REQUEST_CODE = 7301
        private const val LITERT_GEMMA_MIN_RAM_BYTES = 6_000_000_000L
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!isDebuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
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
                "download" -> downloadOnDeviceModel(result)
                "warmup" -> warmupOnDeviceModel(result)
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
            "gt.kan.kan_app/litert_gemma",
        ).setMethodCallHandler { call, result ->
            val modelPath = call.argument<String>("modelPath")?.trim()
            when (call.method) {
                "status" -> {
                    val sha256 = call.argument<String>("sha256")?.trim().orEmpty()
                    checkLiteRtGemmaStatus(modelPath, sha256, result)
                }
                "warmup" -> {
                    val sha256 = call.argument<String>("sha256")?.trim().orEmpty()
                    if (modelPath.isNullOrEmpty()) {
                        result.error("MISSING_MODEL_PATH", "modelPath is required.", null)
                    } else {
                        warmupLiteRtGemma(modelPath, sha256, result)
                    }
                }
                "generate" -> {
                    val prompt = call.argument<String>("prompt")?.trim()
                    val sha256 = call.argument<String>("sha256")?.trim().orEmpty()
                    if (modelPath.isNullOrEmpty()) {
                        result.error("MISSING_MODEL_PATH", "modelPath is required.", null)
                    } else if (prompt.isNullOrEmpty()) {
                        result.error("INVALID_PROMPT", "Prompt must not be empty.", null)
                    } else {
                        generateLiteRtGemma(modelPath, prompt, sha256, result)
                    }
                }
                "downloadModel" -> {
                    val url = call.argument<String>("url")?.trim()
                    val sha256 = call.argument<String>("sha256")?.trim().orEmpty()
                    if (modelPath.isNullOrEmpty()) {
                        result.error("MISSING_MODEL_PATH", "modelPath is required.", null)
                    } else if (url.isNullOrEmpty()) {
                        result.error("MISSING_MODEL_URL", "url is required.", null)
                    } else {
                        downloadLiteRtGemmaModel(url, modelPath, sha256, result)
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
            "gt.kan.kan_app/device_auth",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "confirm" -> {
                    val reason = call.argument<String>("reason")?.trim()
                        ?: "Autorice la prueba local de ZPK Digital ID"
                    confirmDevicePresence(reason, result)
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gt.kan.kan_app/platform_share",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val title = call.argument<String>("title")?.trim().orEmpty()
                    val text = call.argument<String>("text")?.trim().orEmpty()
                    shareText(title, text, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        closeLiteRtEngine()
        scope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (requestCode == DEVICE_AUTH_REQUEST_CODE) {
            val pendingResult = deviceAuthResult
            deviceAuthResult = null
            if (pendingResult != null) {
                val verified = resultCode == Activity.RESULT_OK
                pendingResult.success(
                    mapOf(
                        "verified" to verified,
                        "method" to "android-keyguard",
                    ),
                )
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun confirmDevicePresence(reason: String, result: MethodChannel.Result) {
        if (deviceAuthResult != null) {
            result.error(
                "DEVICE_AUTH_IN_PROGRESS",
                "A device authentication request is already active.",
                null,
            )
            return
        }
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isDeviceSecure) {
            result.error(
                "DEVICE_NOT_SECURE",
                "Configure Android screen lock before issuing authentication proofs.",
                mapOf("method" to "android-keyguard"),
            )
            return
        }
        val intent = keyguard.createConfirmDeviceCredentialIntent(
            "ZPK Digital ID",
            reason,
        )
        if (intent == null) {
            result.error(
                "DEVICE_AUTH_UNAVAILABLE",
                "Android device credential confirmation is unavailable.",
                mapOf("method" to "android-keyguard"),
            )
            return
        }
        deviceAuthResult = result
        startActivityForResult(intent, DEVICE_AUTH_REQUEST_CODE)
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

    private fun downloadOnDeviceModel(result: MethodChannel.Result) {
        scope.launch {
            try {
                val generativeModel = Generation.getClient()
                val events = mutableListOf<Map<String, Any>>()
                generativeModel.download().collect { status ->
                    events.add(downloadStatusMap(status))
                }
                val status = generativeModel.checkStatus()
                result.success(
                    mapOf(
                        "status" to statusName(status),
                        "model" to "mlkit-genai-prompt-aicore",
                        "events" to events,
                    ),
                )
            } catch (error: Throwable) {
                result.error(
                    "MLKIT_GEMMA_DOWNLOAD_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun warmupOnDeviceModel(result: MethodChannel.Result) {
        scope.launch {
            try {
                val generativeModel = Generation.getClient()
                generativeModel.warmup()
                result.success(
                    mapOf(
                        "status" to "READY",
                        "model" to "mlkit-genai-prompt-aicore",
                    ),
                )
            } catch (error: Throwable) {
                result.error(
                    "MLKIT_GEMMA_WARMUP_ERROR",
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

    private fun checkLiteRtGemmaStatus(
        modelPath: String?,
        expectedSha256: String,
        result: MethodChannel.Result,
    ) {
        if (modelPath.isNullOrEmpty()) {
            result.success(
                mapOf(
                    "status" to "MISSING_MODEL_PATH",
                    "model" to "gemma-4-E2B-it-litertlm",
                ),
            )
            return
        }
        scope.launch {
            try {
                val status = withContext(Dispatchers.IO) {
                    val modelFile = safeLiteRtModelFile(modelPath)
                    val partialFile = File(modelFile.parentFile, "${modelFile.name}.part")
                    val expectedFile = File(modelFile.parentFile, "${modelFile.name}.bytes")
                    val expectedBytes = expectedFile
                        .takeIf { it.exists() && it.isFile }
                        ?.readText(Charsets.UTF_8)
                        ?.trim()
                        ?.toLongOrNull()
                    if (!modelFile.exists() || !modelFile.isFile) {
                        if (partialFile.exists() && partialFile.isFile) {
                            return@withContext mapOf(
                                "status" to "DOWNLOADING",
                                "model" to "gemma-4-E2B-it-litertlm",
                                "modelPath" to modelPath,
                                "partialSizeBytes" to partialFile.length(),
                                "expectedBytes" to (expectedBytes ?: 0L),
                            )
                        }
                        return@withContext mapOf(
                            "status" to "MISSING_MODEL",
                            "model" to "gemma-4-E2B-it-litertlm",
                            "modelPath" to modelPath,
                            "expectedBytes" to (expectedBytes ?: 0L),
                        )
                    }
                    val sidecarSha = File(modelFile.parentFile, "${modelFile.name}.sha256")
                        .takeIf { it.exists() && it.isFile }
                        ?.readText(Charsets.UTF_8)
                        ?.trim()
                    val response = mutableMapOf<String, Any>(
                        "status" to "AVAILABLE",
                        "model" to "gemma-4-E2B-it-litertlm",
                        "modelPath" to modelPath,
                        "modelSizeBytes" to modelFile.length(),
                    )
                    if (expectedSha256.isNotEmpty()) {
                        val actualSha256 = sidecarSha
                        response["sha256"] = actualSha256 ?: "not_verified_in_status"
                        response["sha256Expected"] = expectedSha256
                        response["hashVerification"] =
                            if (actualSha256 == null) "deferred_to_install_or_warmup" else "sidecar"
                        if (
                            actualSha256 != null &&
                            !actualSha256.equals(expectedSha256, ignoreCase = true)
                        ) {
                            response["status"] = "CORRUPT_MODEL"
                        }
                    }
                    if (response["status"] == "AVAILABLE" && isAndroidEmulator()) {
                        response["status"] = "EMULATOR_UNSUPPORTED"
                        response["runtimeGuard"] = "android-emulator-native-litertlm"
                    }
                    if (response["status"] == "AVAILABLE" && !hasLiteRtMemoryHeadroom()) {
                        response["status"] = "DEVICE_LOW_MEMORY"
                        response["runtimeGuard"] = "android-low-memory-litertlm"
                        response["deviceRamBytes"] = deviceRamBytes()
                        response["requiredRamBytes"] = LITERT_GEMMA_MIN_RAM_BYTES
                    }
                    response
                }
                result.success(status)
            } catch (error: Throwable) {
                result.error(
                    "LITERT_GEMMA_STATUS_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun warmupLiteRtGemma(
        modelPath: String,
        expectedSha256: String,
        result: MethodChannel.Result,
    ) {
        if (isAndroidEmulator()) {
            result.error(
                "LITERT_GEMMA_EMULATOR_UNSUPPORTED",
                "LiteRT-LM Gemma is installed, but Android emulator native generation is disabled to avoid a known LiteRT-LM crash. Use a physical ARM64 device.",
                mapOf(
                    "status" to "EMULATOR_UNSUPPORTED",
                    "model" to "gemma-4-E2B-it-litertlm",
                ),
            )
            return
        }
        if (!hasLiteRtMemoryHeadroom()) {
            result.error(
                "LITERT_GEMMA_LOW_MEMORY",
                "This device has ${deviceRamBytes()} bytes of RAM; Gemma 4 E2B LiteRT-LM needs at least $LITERT_GEMMA_MIN_RAM_BYTES bytes for safe local generation.",
                mapOf(
                    "status" to "DEVICE_LOW_MEMORY",
                    "model" to "gemma-4-E2B-it-litertlm",
                    "deviceRamBytes" to deviceRamBytes(),
                    "requiredRamBytes" to LITERT_GEMMA_MIN_RAM_BYTES,
                ),
            )
            return
        }
        scope.launch {
            try {
                val hashVerification = withContext(Dispatchers.IO) {
                    getOrCreateLiteRtEngine(modelPath, expectedSha256)
                    engineHashVerification()
                }
                result.success(
                    mapOf(
                        "status" to "READY",
                        "model" to "gemma-4-E2B-it-litertlm",
                        "hashVerification" to hashVerification,
                    ),
                )
            } catch (error: Throwable) {
                result.error(
                    "LITERT_GEMMA_WARMUP_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun generateLiteRtGemma(
        modelPath: String,
        prompt: String,
        expectedSha256: String,
        result: MethodChannel.Result,
    ) {
        if (isAndroidEmulator()) {
            result.error(
                "LITERT_GEMMA_EMULATOR_UNSUPPORTED",
                "LiteRT-LM Gemma generation is disabled on Android emulator because the native runtime crashes during engine creation. Use a physical ARM64 device.",
                mapOf(
                    "status" to "EMULATOR_UNSUPPORTED",
                    "model" to "gemma-4-E2B-it-litertlm",
                ),
            )
            return
        }
        if (!hasLiteRtMemoryHeadroom()) {
            result.error(
                "LITERT_GEMMA_LOW_MEMORY",
                "This device has ${deviceRamBytes()} bytes of RAM; Gemma 4 E2B LiteRT-LM needs at least $LITERT_GEMMA_MIN_RAM_BYTES bytes for safe local generation.",
                mapOf(
                    "status" to "DEVICE_LOW_MEMORY",
                    "model" to "gemma-4-E2B-it-litertlm",
                    "deviceRamBytes" to deviceRamBytes(),
                    "requiredRamBytes" to LITERT_GEMMA_MIN_RAM_BYTES,
                ),
            )
            return
        }
        scope.launch {
            try {
                val generation = withContext(Dispatchers.IO) {
                    val engine = getOrCreateLiteRtEngine(modelPath, expectedSha256)
                    val conversationConfig = ConversationConfig(
                        systemInstruction = Contents.of(
                            "ZPK Digital ID. Solo JSON valido. Sin identificadores.",
                        ),
                        samplerConfig = SamplerConfig(
                            topK = 1,
                            topP = 1.0,
                            temperature = 0.0,
                        ),
                    )
                    val text = engine.createConversation(conversationConfig).use { conversation ->
                        conversation.sendMessage(prompt).contents.contents
                            .filterIsInstance<Content.Text>()
                            .joinToString(separator = "") { it.text }
                            .trim()
                    }
                    mapOf(
                        "text" to text,
                        "hashVerification" to engineHashVerification(),
                    )
                }
                val text = generation["text"] as String
                if (text.isEmpty()) {
                    result.error(
                        "EMPTY_RESPONSE",
                        "LiteRT-LM Gemma returned no text.",
                        mapOf("status" to "AVAILABLE"),
                    )
                } else {
                    result.success(
                        mapOf(
                            "text" to text,
                            "status" to "AVAILABLE",
                            "model" to "gemma-4-E2B-it-litertlm",
                            "hashVerification" to generation["hashVerification"],
                        ),
                    )
                }
            } catch (error: Throwable) {
                result.error(
                    "LITERT_GEMMA_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun downloadLiteRtGemmaModel(
        url: String,
        modelPath: String,
        expectedSha256: String,
        result: MethodChannel.Result,
    ) {
        scope.launch {
            try {
                val download = withContext(Dispatchers.IO) {
                    val target = safeLiteRtModelFile(modelPath)
                    val temp = File(target.parentFile, "${target.name}.part")
                    val expectedFile = File(target.parentFile, "${target.name}.bytes")
                    target.parentFile?.mkdirs()

                    val digest = MessageDigest.getInstance("SHA-256")
                    var totalBytes = 0L
                    val connection = URL(url).openConnection().apply {
                        connectTimeout = 30_000
                        readTimeout = 60_000
                    }
                    val expectedBytes = connection.contentLengthLong.takeIf { it > 0L } ?: 0L
                    if (expectedBytes > 0L) {
                        expectedFile.writeText(expectedBytes.toString(), Charsets.UTF_8)
                    }
                    connection.getInputStream().use { input ->
                        temp.outputStream().use { output ->
                            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                            while (true) {
                                val read = input.read(buffer)
                                if (read < 0) {
                                    break
                                }
                                digest.update(buffer, 0, read)
                                output.write(buffer, 0, read)
                                totalBytes += read
                            }
                        }
                    }
                    val actualSha256 = digest.digest().toHex()
                    if (
                        expectedSha256.isNotEmpty() &&
                        !actualSha256.equals(expectedSha256, ignoreCase = true)
                    ) {
                        temp.delete()
                        throw IllegalStateException(
                            "Downloaded LiteRT-LM model hash mismatch: $actualSha256",
                        )
                    }
                    if (target.exists() && !target.delete()) {
                        temp.delete()
                        throw IllegalStateException("Could not replace existing model.")
                    }
                    if (!temp.renameTo(target)) {
                        temp.delete()
                        throw IllegalStateException("Could not move downloaded model into place.")
                    }
                    File(target.parentFile, "${target.name}.sha256")
                        .writeText(actualSha256, Charsets.UTF_8)
                    mapOf(
                        "status" to "AVAILABLE",
                        "model" to "gemma-4-E2B-it-litertlm",
                        "modelPath" to target.absolutePath,
                        "bytes" to totalBytes,
                        "expectedBytes" to expectedBytes,
                        "sha256" to actualSha256,
                    )
                }
                result.success(download)
            } catch (error: Throwable) {
                result.error(
                    "LITERT_GEMMA_DOWNLOAD_ERROR",
                    error.message ?: error.javaClass.simpleName,
                    mapOf("type" to error.javaClass.name),
                )
            }
        }
    }

    private fun getOrCreateLiteRtEngine(modelPath: String, expectedSha256: String): Engine {
        val modelFile = prepareLiteRtModelFile(modelPath, expectedSha256)
        require(modelFile.exists() && modelFile.isFile) {
            "Gemma 4 LiteRT-LM model file does not exist: $modelPath"
        }
        val hashVerification = verifyLiteRtModelHashIfNeeded(modelFile, expectedSha256)
        synchronized(litertLock) {
            val cached = litertEngine
            if (cached != null && litertEngineModelPath == modelFile.absolutePath) {
                litertHashVerification = hashVerification
                return cached
            }
            closeLiteRtEngineLocked()
            val engineConfig = EngineConfig(
                modelPath = modelFile.absolutePath,
                backend = Backend.CPU(numOfThreads = 4),
                maxNumTokens = 2048,
                cacheDir = File(cacheDir, "litert-lm").absolutePath,
            )
            val engine = Engine(engineConfig)
            engine.initialize()
            litertEngine = engine
            litertEngineModelPath = modelFile.absolutePath
            litertHashVerification = hashVerification
            return engine
        }
    }

    private var litertHashVerification: String = "not_required"

    private fun engineHashVerification(): String = litertHashVerification

    private fun verifyLiteRtModelHashIfNeeded(modelFile: File, expectedSha256: String): String {
        if (expectedSha256.isEmpty()) {
            return "not_configured"
        }
        val sidecar = File(modelFile.parentFile, "${modelFile.name}.sha256")
        val sidecarSha = sidecar
            .takeIf { it.exists() && it.isFile }
            ?.readText(Charsets.UTF_8)
            ?.trim()
        if (sidecarSha != null && sidecarSha.equals(expectedSha256, ignoreCase = true)) {
            return "sidecar"
        }
        val actualSha256 = sha256Of(modelFile)
        if (!actualSha256.equals(expectedSha256, ignoreCase = true)) {
            throw IllegalStateException(
                "LiteRT-LM model hash mismatch: $actualSha256",
            )
        }
        sidecar.writeText(actualSha256, Charsets.UTF_8)
        return if (sidecarSha == null) "computed" else "computed_sidecar_repaired"
    }

    private fun prepareLiteRtModelFile(modelPath: String, expectedSha256: String): File {
        val source = safeLiteRtModelFile(modelPath)
        val externalRoot = getExternalFilesDir(null)?.canonicalFile
        val isExternal = externalRoot != null &&
            (source.path == externalRoot.path || source.path.startsWith("${externalRoot.path}/"))
        if (!isExternal) {
            return source
        }

        require(source.exists() && source.isFile) {
            "Gemma 4 LiteRT-LM model file does not exist: $modelPath"
        }

        val internalDir = File(filesDir, "models")
        val internal = File(internalDir, source.name).canonicalFile
        internal.parentFile?.mkdirs()

        val externalSidecar = File(source.parentFile, "${source.name}.sha256")
            .takeIf { it.exists() && it.isFile }
            ?.readText(Charsets.UTF_8)
            ?.trim()
        val internalSidecar = File(internal.parentFile, "${internal.name}.sha256")
        val internalSha = internalSidecar
            .takeIf { it.exists() && it.isFile }
            ?.readText(Charsets.UTF_8)
            ?.trim()

        val internalReady = internal.exists() &&
            internal.isFile &&
            internal.length() == source.length() &&
            (
                expectedSha256.isEmpty() ||
                    internalSha?.equals(expectedSha256, ignoreCase = true) == true
            )
        if (internalReady) {
            return internal
        }

        val temp = File(internal.parentFile, "${internal.name}.importing")
        if (temp.exists()) {
            temp.delete()
        }
        source.inputStream().use { input ->
            temp.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        if (internal.exists() && !internal.delete()) {
            temp.delete()
            throw IllegalStateException("Could not replace imported internal model.")
        }
        if (!temp.renameTo(internal)) {
            temp.delete()
            throw IllegalStateException("Could not move imported model into internal storage.")
        }

        val shaForSidecar = externalSidecar
            ?: if (expectedSha256.isNotEmpty()) expectedSha256 else sha256Of(internal)
        internalSidecar.writeText(shaForSidecar, Charsets.UTF_8)
        return internal
    }

    private fun safeLiteRtModelFile(modelPath: String): File {
        val target = File(modelPath)
        val canonicalTarget = target.canonicalFile
        val allowedRoots = listOfNotNull(
            filesDir,
            getExternalFilesDir(null),
        ).map { it.canonicalFile }
        val isAllowed = allowedRoots.any { root ->
            canonicalTarget.path == root.path ||
                canonicalTarget.path.startsWith("${root.path}/")
        }
        require(isAllowed) {
            "LiteRT-LM model must be stored under app-private internal or external files directory."
        }
        return canonicalTarget
    }

    private fun isAndroidEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return fingerprint.contains("generic") ||
            fingerprint.contains("sdk_gphone") ||
            model.contains("sdk_gphone") ||
            model.contains("emulator") ||
            product.contains("sdk_gphone") ||
            product.contains("emulator") ||
            hardware.contains("ranchu") ||
            hardware.contains("goldfish") ||
            manufacturer.contains("genymotion")
    }

    private fun hasLiteRtMemoryHeadroom(): Boolean =
        deviceRamBytes() >= LITERT_GEMMA_MIN_RAM_BYTES

    private fun deviceRamBytes(): Long {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.totalMem
    }

    private fun sha256Of(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) {
                    break
                }
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().toHex()
    }

    private fun closeLiteRtEngine() {
        synchronized(litertLock) {
            closeLiteRtEngineLocked()
        }
    }

    private fun closeLiteRtEngineLocked() {
        litertEngine?.close()
        litertEngine = null
        litertEngineModelPath = null
        litertHashVerification = "not_required"
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

    private fun shareText(title: String, text: String, result: MethodChannel.Result) {
        if (text.isEmpty()) {
            result.error("INVALID_SHARE_TEXT", "Text to share must not be empty.", null)
            return
        }
        try {
            val subject = title.ifEmpty { "ZPK Digital ID" }
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
            }
            startActivity(Intent.createChooser(sendIntent, subject))
            result.success(mapOf("status" to "opened"))
        } catch (error: Throwable) {
            result.error(
                "SHARE_SHEET_ERROR",
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

    private fun downloadStatusMap(status: DownloadStatus): Map<String, Any> =
        when (status) {
            is DownloadStatus.DownloadStarted -> mapOf(
                "event" to "started",
                "bytesToDownload" to status.bytesToDownload,
            )
            is DownloadStatus.DownloadProgress -> mapOf(
                "event" to "progress",
                "totalBytesDownloaded" to status.totalBytesDownloaded,
            )
            is DownloadStatus.DownloadCompleted -> mapOf("event" to "completed")
            is DownloadStatus.DownloadFailed -> mapOf(
                "event" to "failed",
                "error" to (status.e.message ?: status.e.javaClass.simpleName),
            )
        }
}
