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
"foodCategory": "meat|poultry|seafood|salad|vegetables|fruit|grain|soup|sandwich|pizza|asian|mexican|dessert|snack|breakfast|dairy|coffee|tea|alcohol|smoothie|soda|juice|water|other",
"items": [
{
"name": "Item name (1-6 words)",
"quantity": 1,
"unit": "serving|piece|slice|cup|bowl|plate|g|ml",
"estimatedWeightG": 0,
"estimatedVolumeML": 0,
"caloriesKcal": 0,
"macros": { "proteinG": 0, "carbsG": 0, "fatG": 0, "fiberG": 0, "sugarG": 0 },
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0, "caffeineMg": 0 },
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
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0, "caffeineMg": 0 }
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
* **isFood detection**: Set isFood to false if the image does not contain any food or drinks (e.g., a person, animal, object, landscape, document). When isFood is false, set foodName to a brief description of what you see (e.g., "a cat", "office supplies", "a car"), set foodCategory to "other", set all nutritional values to 0, use "red" rating, and set ratingReason to explain why this is not food.
* **Caffeine estimation**: Estimate caffeine content (caffeineMg) for beverages and foods that contain it. Reference values: brewed coffee ~95mg/8oz, espresso ~63mg/shot, black tea ~47mg/8oz, green tea ~28mg/8oz, cola ~34mg/12oz, energy drinks vary (check label if visible), dark chocolate ~12mg/oz. Set to 0 for non-caffeinated items.
* **foodCategory**: Choose the single best-matching category for the overall meal. Use these guidelines:
  * meat: beef, pork, lamb, game
  * poultry: chicken, turkey, duck
  * seafood: fish, shrimp, crab, shellfish, sushi with fish
  * salad: leafy green salads, mixed salads
  * vegetables: cooked vegetables, vegetable sides
  * fruit: fresh fruit, fruit salad, fruit-based dishes
  * grain: rice, pasta, bread, cereals, oatmeal
  * soup: soups, stews, broths, chili
  * sandwich: sandwiches, burgers, wraps, subs
  * pizza: pizza, flatbreads with toppings
  * asian: stir-fry, noodle dishes, dim sum, curry, ramen, pho
  * mexican: tacos, burritos, nachos, enchiladas, quesadillas
  * dessert: cakes, cookies, ice cream, pastries, candy
  * snack: chips, crackers, nuts, popcorn, small bites
  * breakfast: eggs, pancakes, waffles, bacon, breakfast cereal
  * dairy: cheese plates, yogurt, milk-based dishes
  * coffee: coffee drinks (espresso, latte, cappuccino)
  * tea: tea beverages (hot or iced)
  * alcohol: beer, wine, cocktails, spirits
  * smoothie: smoothies, protein shakes, milkshakes
  * soda: soft drinks, carbonated beverages
  * juice: fruit or vegetable juices
  * water: plain or sparkling water
  * other: anything that doesn't fit the above categories
"""

let textMealAnalysisPrompt = """
Analyze the following text description of a meal or drink and estimate its nutrition. Use your knowledge of typical portion sizes and nutritional values.

USER DESCRIPTION: {{DESCRIPTION}}

Return **ONLY** a single valid JSON object (no markdown, no extra text). Use this exact schema and types:

{
"isFood": true,
"foodName": "Short overall name (1-6 words)",
"foodCategory": "meat|poultry|seafood|salad|vegetables|fruit|grain|soup|sandwich|pizza|asian|mexican|dessert|snack|breakfast|dairy|coffee|tea|alcohol|smoothie|soda|juice|water|other",
"items": [
{
"name": "Item name (1-6 words)",
"quantity": 1,
"unit": "serving|piece|slice|cup|bowl|plate|g|ml",
"estimatedWeightG": 0,
"estimatedVolumeML": 0,
"caloriesKcal": 0,
"macros": { "proteinG": 0, "carbsG": 0, "fatG": 0, "fiberG": 0, "sugarG": 0 },
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0, "caffeineMg": 0 },
"confidence": 0.0,
"evidence": [
"Short bullet-like phrases describing what was mentioned in the description"
],
"assumptions": [
"Assumptions made about portion size, preparation method, or ingredients not specified"
]
}
],
"totals": {
"caloriesKcal": 0,
"macros": { "proteinG": 0, "carbsG": 0, "fatG": 0, "fiberG": 0, "sugarG": 0 },
"micros": { "sodiumMg": 0, "cholesterolMg": 0, "satFatG": 0, "caffeineMg": 0 }
},
"rating": "green|yellow|red",
"ratingReason": "One short sentence (why this rating)",
"healthNotes": [
"Up to 3 short notes: positives/risks (e.g., 'high sodium', 'good fiber', 'high added sugar')"
],
"uncertainty": {
"overallConfidence": 0.0,
"biggestSources": [
"Up to 3 major uncertainties (e.g., 'portion size not specified', 'cooking method unknown')"
]
}
}

Rules & guidance:

* If the description mentions specific quantities (e.g., "large coffee", "two slices"), use those. Otherwise, assume typical serving sizes.
* If the description is vague (e.g., "some pasta"), use reasonable default portions and note this in assumptions.
* Use **grams/ml** when possible for weight/volume estimates.
* caloriesKcal and macro/micro values should be **best estimates**; use 0 only when truly unknowable.
* confidence fields are from 0.0 to 1.0 (how sure you are about that item). Text descriptions typically have lower confidence than photos.
* rating:
  * green: mostly whole foods, high protein/fiber, low added sugar, moderate calories, lower sodium/sat fat
  * yellow: mixed/processed or higher calories but reasonable balance
  * red: very high calories for portion, highly processed, high added sugar and/or sodium and/or sat fat
* Ensure totals equal the sum of items (within rounding).
* Output must be strict JSON (double quotes, no trailing commas).
* Round grams to nearest 5 g, calories to nearest 10 kcal.
* **isFood detection**: Set isFood to false if the description clearly refers to non-food items. When isFood is false, set foodName to describe what was mentioned, set foodCategory to "other", set all nutritional values to 0, use "red" rating.
* **Caffeine estimation**: Estimate caffeine content (caffeineMg) for beverages and foods that contain it. Reference values: brewed coffee ~95mg/8oz, espresso ~63mg/shot, black tea ~47mg/8oz, green tea ~28mg/8oz, cola ~34mg/12oz, energy drinks vary, dark chocolate ~12mg/oz. Set to 0 for non-caffeinated items.
* **foodCategory**: Choose the single best-matching category for the overall meal. Use these guidelines:
  * meat: beef, pork, lamb, game
  * poultry: chicken, turkey, duck
  * seafood: fish, shrimp, crab, shellfish, sushi with fish
  * salad: leafy green salads, mixed salads
  * vegetables: cooked vegetables, vegetable sides
  * fruit: fresh fruit, fruit salad, fruit-based dishes
  * grain: rice, pasta, bread, cereals, oatmeal
  * soup: soups, stews, broths, chili
  * sandwich: sandwiches, burgers, wraps, subs
  * pizza: pizza, flatbreads with toppings
  * asian: stir-fry, noodle dishes, dim sum, curry, ramen, pho
  * mexican: tacos, burritos, nachos, enchiladas, quesadillas
  * dessert: cakes, cookies, ice cream, pastries, candy
  * snack: chips, crackers, nuts, popcorn, small bites
  * breakfast: eggs, pancakes, waffles, bacon, breakfast cereal
  * dairy: cheese plates, yogurt, milk-based dishes
  * coffee: coffee drinks (espresso, latte, cappuccino)
  * tea: tea beverages (hot or iced)
  * alcohol: beer, wine, cocktails, spirits
  * smoothie: smoothies, protein shakes, milkshakes
  * soda: soft drinks, carbonated beverages
  * juice: fruit or vegetable juices
  * water: plain or sparkling water
  * other: anything that doesn't fit the above categories
"""
