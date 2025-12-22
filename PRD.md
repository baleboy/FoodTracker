# Food Tracker - an image based meal tracker

Food tracker is an application to record what you eat, keep track of your eating habits and manage your fasting windows to help you eat more healtily. It uses AI to evaluate the food you eat.

## Main functionality

Food tracker is primarily driven by taking photos. A user takes a photo of something they are about to eat and receive feedback on the estimated number of calories and red/yellow/green rating for the meal. The meal historuy is recorded and can be looked at later as a timeline. Days are classified as "red", "yellow" or "green" based on the overall food intake of that day. The application also updates fasting time, for example if a user is fasting and takes a photo of a meal the fasting ends, otherwise the app tells the time fasting until now.

Calorie estimates and red/yellow/green judgment are done by contacting an LLM (openAI or others, haven't decided yet. I already have a Claude subscription if that helps) and giving a prompt with the image of the food to identify what it is, what is the calorie intake and the nutrional score. If the LLM has follow up questions ("is this cooked with butter or oil") the app presents them as multiple choices to the user. This means that the response from the LLM needs to be structures, e.g. with a JSON schema or similar.