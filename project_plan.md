# Project Plan: Birthday Jump (Working Title)

## 1. Project Overview
* **Project Name:** Well of 21 Letters
* **Description:** A mobile vertical platformer inspired by "Jump King", designed as a special 21st birthday gift.
* **Story & Premise:** 
  * **Intro Cutscene:** The player character slips on a banana peel and tumbles deep down into a well shaft, landing at the very bottom of the tower with all 21 birthday letters scattered across the climb.
  * **Core Climb:** The player climbs the massive vertical tower, retrieving all 21 letters from letter bundles along the way.
  * **Ending Cutscene:** Upon reaching the well shaft at the summit with all 21 letters, an animated cutscene plays: the player pops out of the well shaft, lands safely on the left platform, does a happy bounce, and auto-runs across to the right side of the screen to deliver all 21 letters to his girlfriend, triggering the 21st Birthday Victory celebration!
* **Target Audience:** Your girlfriend (for her 21st birthday).
* **Platform:** Mobile (Android/iOS).
* **Core Loop:** Platforming upwards, avoiding long falls, collecting 21 letters, and reaching the peak for a birthday surprise.

## 2. Gameplay & Mechanics
* **Controls:** Simplified touchscreen controls for easy mobile play.
  * **Left Button:** Move left.
  * **Right Button:** Move right.
  * **Jump Button:** Standard jump (no complex charge-jump mechanics).
* **Progression:** A continuous vertical level design. Falling drops the player to lower platforms, creating Jump King-style tension.
* **Collectibles:** 21 distinct "Letters". They act as milestones and are required (or highly encouraged) to reach the final birthday message.

## 3. Goals & Scope
* **Must-Haves (MVP):**
  * Core platforming mechanics (Left, Right, Jump) tuned for mobile.
  * Invisible Auto-Save System (saves player position and letter count to prevent progress loss if the phone OS closes the app).
  * Simple Main Menu (just "New Game" and "Continue" hooked up to the auto-save).
  * Mobile on-screen touch UI (CanvasLayer with TouchScreenButtons).
  * A single, tall continuous vertical level.
  * 21 collectible letters scattered throughout the climb.
  * A final victory area displaying a personalized 21st birthday message.
* **Art & Visuals:**
  * **Environment:** Custom hand-painted backgrounds, while still keeping the **Jump King-inspired aesthetic** (atmospheric ruins, dark fantasy, distinct zones). Pipeline: Block out level in Godot -> Export layout to Figma/Photoshop -> Paint the environment -> Re-import as Sprite layers over invisible collision blocks.
  * **Characters:** Hand-drawn "derpy chibi" versions of you and your girlfriend to make it cute, personal, and funny.
* **Out of Scope:**
  * Enemies or combat systems.
  * Multiple save slots, settings screens, or complex UI (keep it strictly to the essentials).
  * Procedural generation (the level should be hand-crafted for fairness).

## 4. Tech Stack
* **Game Engine:** Godot Engine (Ideal for 2D mobile games).
* **Language:** GDScript.
* **Export:** Mobile (Likely Android APK, unless you plan to sideload onto an iPhone).
* **Data Privacy / Modularity:** Letter contents will be stored in an external `letters.json` file (added to `.gitignore`). A template `letters.example.json` will be used for the public repo to keep your personal messages completely private.

## 5. Timeline & Deadline
* **Hard Deadline:** August 6th (One week before her birthday on August 13th).
* **Time Available:** ~4 Weeks (Current date: July 9th).
* **Constraints:** Must balance game development with upcoming hackathons.
* **Strategy:** Prioritize the MVP (movement and invisible blockout). Finish coding quickly so you can spend your limited time painting the environment in Figma without worrying about bugs.

## 6. Key Milestones & Phases
### Phase 1: Prototyping & Foundation
- [x] Set up the Godot project with mobile portrait resolution (e.g., 720x1280 or 1080x1920).
- [x] Implement the `CharacterBody2D` player with basic movement and gravity.
- [x] Set up the on-screen touch controls and map them to standard input actions.
- [x] Block out a small test level to tune jump heights, movement speed, and gravity.

### Phase 2: Core Development & Level Design
- [x] Block out the entire vertical map using simple Godot collision shapes (StaticBody2D).
- [x] Create the "Letter" collectible using `Area2D` and implement a global counter (0/21).
- [x] Set up JSON parsing in GDScript to load the personal messages dynamically from `letters.json`.
- [x] Create a basic Main Menu scene with "New Game" and "Continue" buttons.
- [x] Strategically place the 21 letters across different platforming challenges (via 7 letter bundles).
- [x] Implement Jump King screen-by-screen camera snapping.
- [x] Implement opening narrative intro cutscene (banana slip on summit, immediate parabolic launch into well shaft, skydiving tumble fall with enveloped side-to-side sway, and landing at bottom guided by dynamic `BananaPeel` & `FallTarget` editor props).
- [x] Implement Summit finish cutscene (automatic finish trigger at peak checking all 21 letters, well pop-out arc, run to girlfriend, and 21st Birthday Victory modal).

### Phase 3: Polish, Art & Audio
- [x] Export/screenshot the Godot level blockout and import it into Figma/Photoshop.
- [x] Hand-paint the environment art over the blockout and export it as large background slices.
- [x] Import the painted backgrounds into Godot and align them perfectly over the invisible collision blocks.
- [x] Add the hand-drawn derpy chibi character sprites and animations.
- [x] Add player animations (Idle, Walk, Jump, Fall).
- [x] Add a UI HUD to show how many letters have been collected, with interactive inventory journal modal.
- [X] Inventory Hud redesign
- [ ] Top Bar Hud redesign
- [X] Open Letter Hud. Plan to add a 3d animation of the letter itself opening from being folded. Need to find out if possible via code or not.
- [x] ~Finish Modal~ Show main menu with new "Read Letters" button, showing inventory without playing the game. Also need a separate save file tracker so the letters acts as an achievent type of thing. A global inventory. When starting new game letter doesn't dissapear from this one.
- [X] Completely change the letter system so it's actually a picture of a decorated letter (digital ofc), not a text

### Phase 4: The Birthday Surprise & Release
- [ ] Implement custom SFX and YouTube-sourced BGM (ensure credits are included at the end).
- [ ] fix the goddamn button design
- [x] Create the "Summit" scene—a celebratory screen that triggers when the top is reached (checking if all 21 letters are found).
- [ ] Block the well if not all letters are collected, make the counter shake as an indicator.
- [X] Playtest thoroughly to ensure it is fun and not overly frustrating.
- [ ] Export Android APK. Delivery: Send via WhatsApp (fallback: let her play it directly on my phone).
