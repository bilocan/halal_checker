# ML Kit: we only use Latin script, so suppress missing-class warnings for
# the optional Chinese/Devanagari/Japanese/Korean recognizer modules.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
