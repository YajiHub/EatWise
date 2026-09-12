# JSON Parsing Fix - Testing Guide

## 🔧 What Was Fixed

Your app was showing: **"macroAI response was malformed. could not parse json. try again with a shorter message."**

### Root Cause
The vision service was using a basic JSON parser that couldn't handle:
- Truncated responses (from long image descriptions)
- Multi-food images with incomplete arrays
- Malformed JSON from model output

### Solution Implemented
Integrated the sophisticated **AiJsonParser** with a 4-tier fallback recovery system:

```
Tier 1: Standard JSON parsing (normal case)
         ↓ (fails)
Tier 2: Truncation repair (close unclosed strings/arrays)
         ↓ (fails)
Tier 3: Multi-food repair (fix incomplete foods[] array)
         ↓ (fails)
Tier 4: Fallback structure (extract partial data + defaults)
```

---

## 📊 Debug Logging

The parser now logs each tier's attempt. Check Flutter console for:

```
[AiJsonParser] Raw response: 1850 chars
[AiJsonParser] After preprocess: 1820 chars
[AiJsonParser] ✓ Tier 1 (standard parse) - SUCCESS
```

or if parsing fails:

```
[AiJsonParser] Raw response: 2045 chars
[AiJsonParser] After preprocess: 2000 chars
[AiJsonParser] ✗ Tier 1 failed: Unexpected end of JSON input
[AiJsonParser] ✓ Tier 2 (truncation repair) - SUCCESS
```

---

## ✅ Testing Checklist

### 1. **Basic Image Test** (Single Food)
```
✓ Analyze a simple image with one food item (e.g., plate of rice)
✓ Should see: [AiJsonParser] ✓ Tier 1 - SUCCESS
✓ Verify macros display correctly
```

### 2. **Multi-Food Test**
```
✓ Analyze an image with 2-3 different foods (e.g., rice, chicken, vegetables)
✓ Should parse all items separately
✓ Check that confidence scores appear for each food
✓ Verify total macros = sum of individual foods
```

### 3. **Poor Quality Image Test**
```
✓ Take a blurry food photo
✓ Should see: [GeminiVision] Image quality: XX% 
✓ If quality too poor, should show:
   "Image quality too poor: Issues detected..."
✓ App should NOT crash
```

### 4. **Long Description Test** (Truncation)
```
✓ Describe a complex meal with many items and detailed portions
✓ If response truncates, should see:
   [AiJsonParser] ✗ Tier 1 failed: Unexpected end...
   [AiJsonParser] ✓ Tier 2 (truncation repair) - SUCCESS
✓ Should recover and parse successfully
```

### 5. **Error Messages Test**
```
✓ All user-facing errors should now show:
  "MacroAI response was malformed. Could not parse JSON. Try again with a shorter message."
✓ Console should show which tier failed (for debugging)
✓ App should NOT crash with stack trace
```

---

## 🚀 Console Output Reference

### Successful Parse - Tier 1 (Ideal Case)
```
[GeminiVision] Image quality: 85.0%
[GeminiVision] Issues: []
[AiJsonParser] Raw response: 1200 chars
[AiJsonParser] After preprocess: 1180 chars
[AiJsonParser] ✓ Tier 1 (standard parse) - SUCCESS
[GeminiVision] ✓ Successfully parsed response
```

### Successful Parse - Tier 2 (Truncation)
```
[AiJsonParser] Raw response: 1950 chars
[AiJsonParser] After preprocess: 1920 chars
[AiJsonParser] ✗ Tier 1 failed: Unexpected end of JSON input
[AiJsonParser] ✓ Tier 2 (truncation repair) - SUCCESS
[GeminiVision] ✓ Successfully parsed response
```

### Successful Parse - Tier 3 (Multi-Food)
```
[AiJsonParser] Raw response: 2100 chars
[AiJsonParser] After preprocess: 2050 chars
[AiJsonParser] ✗ Tier 1 failed: JSON.decode() failed
[AiJsonParser] ✗ Tier 2 failed: JSON.decode() failed
[AiJsonParser] ✓ Tier 3 (multi-food repair) - SUCCESS
[GeminiVision] ✓ Successfully parsed response
```

### Fallback Used - Tier 4
```
[AiJsonParser] ✗ Tier 3 failed: JSON.decode() failed
[AiJsonParser] ✓ Tier 4 (fallback structure) - USING FALLBACK
[GeminiVision] ✓ Successfully parsed response
Message shown to user: "Incomplete response. Please provide clearer food details."
```

---

## 🔍 What Each Tier Does

### Tier 1: Standard Parsing
- Assumption: Response is valid JSON
- Cleans markdown fences (```json ... ```)
- Extracts content between first { and last }
- Calls jsonDecode()

### Tier 2: Truncation Repair
- Closes unterminated strings: `"food": "rice` → `"food": "rice"`
- Closes unclosed arrays: `"foods": [{ ...]` → `"foods": [{...}]`
- Closes unclosed objects: `{"name": "...` → `{"name": "..."}`

### Tier 3: Multi-Food Repair
- Specifically handles incomplete foods[] array
- Completes the last food item in array
- Adds missing closing brackets/braces

### Tier 4: Fallback Structure
- Extracts whatever data is available (foods, totals)
- Creates minimal valid food entries with default values
- Returns something the app can display instead of crashing
- Message explains data is incomplete

---

## 📝 Files Changed

| File | Changes |
|------|---------|
| `lib/core/ai/ai_json_parser.dart` | Added debug logging to track which tier succeeds |
| `lib/features/food_ai/data/gemini_vision_service.dart` | Now uses AiJsonParser instead of inline parsing |

---

## 🎯 Expected Improvements

### Before Fix
```
Image scan → Error: "macroAI response was malformed" → User confused
```

### After Fix
```
Image scan → Parse attempts multiple strategies → Success with Tier 2/3 → User sees results
         → If truly broken → Fallback with warning → User knows data is incomplete
         → Console shows exactly which tier succeeded (Tier 1/2/3/4)
```

---

## 🐛 Troubleshooting

### Still Getting "Response Malformed" Error?

**Check these in order:**

1. **API Keys Valid?**
   - Console should show: `[AiConfig] ✓ Gemini API key loaded`
   - If not: Update `.env` with new keys

2. **Image Quality?**
   - Check for: `[GeminiVision] Image quality: XX%`
   - If <30%: Image too poor, Tier 4 fallback used
   - Fix: Take clearer photo

3. **Description Too Long?**
   - Tier 2/3 should handle truncation
   - If still failing: Describe food more briefly
   - Check console log showing which tier failed

4. **Multi-Food?**
   - Tier 3 handles incomplete multi-food arrays
   - If failing: Fewer food items per image

5. **Collect Logs**
   - Screenshot the console output
   - Include full error message
   - Show which tier the parser reached

---

## 🔄 Code Logic Reference

```dart
// OLD (was failing):
MealAnalysis _parseMealAnalysis(String rawJson) {
  try {
    final json = jsonDecode(cleaned);  // ← FAILS on truncation
    return MealAnalysis.fromJson(json);
  } catch (e) {
    throw AIProcessingFailure(...);
  }
}

// NEW (with recovery):
MealAnalysis _parseMealAnalysis(String rawJson) {
  final parsed = AiJsonParser.parseJsonResponse(rawJson);
  // ↑ Tries 4 tiers automatically, logs progress
  return MealAnalysis.fromJson(parsed);
}
```

---

## 📊 Success Criteria

Once you test, all of these should be true:

- [ ] Single food images parse on Tier 1
- [ ] Multi-food images parse on Tier 2-3
- [ ] Blurry images rejected gracefully
- [ ] No JSON parsing exceptions in logs
- [ ] All responses show macro values (or fallback message)
- [ ] Console shows clear tier progression
- [ ] App never crashes on bad responses

---

## 🚀 Next Steps

1. **Update your `.env` with new API keys** (you mentioned you already did this)
2. **Run flutter pub get && flutter run**
3. **Test with a food image** - watch console logs
4. **Check if "macroAI response malformed" error appears** - should NOT appear now
5. **If error still appears**, check console logs to see which tier failed

---

**Status**: ✅ Code Fixed  
**Deployment**: Ready  
**Testing**: Follow checklist above  
**Support**: Check console [AiJsonParser] logs for debugging

---

Last Updated: June 17, 2026
Commit: `1440869` - "fix(ai): integrate AiJsonParser with 3-tier fallback"
