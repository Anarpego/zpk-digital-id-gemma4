# flutter_gemma pulls MediaPipe framework classes that reference optional proto
# types not packaged by the Android artifact. The generated app code does not
# use these profiler/template APIs, so release R8 can safely ignore them.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
