//
//  MealPrompt.swift
//  FoodTracker
//
//  This file contains the prompt used for meal analysis.
//  Edit this file to modify how the AI analyzes food images.
//

import Foundation

let mealAnalysisPrompt = """
Analyze the provided photo and determine if it contains food or drinks. If it does, estimate nutrition using **all available evidence in the image** (e.g., portion size, number of items, thickness, plate/bowl size, utensils for scale, packaging labels, restaurant/menu text, and **kitchen scale readings** if present). If multiple foods/drinks are present, include them all.

Return **ONLY** a single valid JSON object (no markdown, no extra text). Use this exact schema and types:

{
"isFood": true,
"foodName": "Short overall name (1-6 words)",
"items": [
{
"name": "Item name (1-6 words)",
"quantity": 1,
"unit": "serving|piece|slice|cup|bowl|plate|g|ml",
"estimatedWeightG": 0,
"estimatedVolumeML": 0,
"caloriesKcal": 0,
"macros": { "proteinG": 0, "carbsG": 0, "fatG": 0, "fiberG": 0, "sugarG": 0 },
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0 },
"confidence": 0.0,
"evidence": [
"Short bullet-like phrases describing visual cues used (e.g., 'scale shows 182 g', 'standard 24 cm dinner plate', '12 oz can visible')"
],
"assumptions": [
"Only if needed; be explicit (e.g., 'assumed cooked weight', 'assumed whole-milk cheese')"
]
}
],
"totals": {
"caloriesKcal": 0,
"macros": { "proteinG": 0, "carbsG": 0, "fatG": 0, "fiberG": 0, "sugarG": 0 },
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0 }
},
"rating": "green|yellow|red",
"ratingReason": "One short sentence (why this rating)",
"healthNotes": [
"Up to 3 short notes: positives/risks (e.g., 'high sodium', 'good fiber', 'high added sugar')"
],
"uncertainty": {
"overallConfidence": 0.0,
"biggestSources": [
"Up to 3 major uncertainties (e.g., 'unknown dressing amount', 'oil used in cooking')"
]
}
}

Rules & guidance:

* Use **grams/ml** when possible. If the photo includes a **scale readout**, use that number for estimatedWeightG.
* If packaging or nutrition labels are visible/readable, prefer them over generic estimates and mention them in evidence.
* If you can’t infer weight/volume, estimate from size cues (plate/utensils/hand/can) and state the cue in evidence.
* caloriesKcal and macro/micro values should be **best estimates**; use 0 only when truly unknowable, and then explain in uncertainty.
* confidence fields are from 0.0 to 1.0 (how sure you are about that item).
* rating:

  * green: mostly whole foods, high protein/fiber, low added sugar, moderate calories, lower sodium/sat fat
  * yellow: mixed/processed or higher calories but reasonable balance
  * red: very high calories for portion, highly processed, high added sugar and/or sodium and/or sat fat
* Ensure totals equal the sum of items (within rounding).
* Output must be strict JSON (double quotes, no trailing commas).
* Round grams to nearest 5 g, calories to nearest 10 kcal unless label provides exact values.
* **isFood detection**: Set isFood to false if the image does not contain any food or drinks (e.g., a person, animal, object, landscape, document). When isFood is false, set foodName to a brief description of what you see (e.g., "a cat", "office supplies", "a car"), set all nutritional values to 0, use "red" rating, and set ratingReason to explain why this is not food.
"""
