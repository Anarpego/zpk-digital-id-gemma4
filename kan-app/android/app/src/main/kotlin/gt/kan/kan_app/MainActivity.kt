package gt.kan.kan_app

import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gt.kan.kan_app/mlkit_gemma",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        scope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
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
}
