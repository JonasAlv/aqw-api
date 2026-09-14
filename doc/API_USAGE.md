# AQW Enhanced API Usage Guide

The AQW Enhanced API is a lightweight ActionScript 3 (AS3) library designed to interact with the AQW game client. It provides a clean interface for scripting, combat automation, inventory management, and questing without exposing complex internal game mechanics to the user.

## Compatibility & Testing
This API is designed to be injected into the AQW client as a neutral engine. It relies on standard ActionScript 3.0 APIs and is entirely platform-agnostic—whether you are building a custom wrapper in AIR, a C# projection, or a web extension, it exposes a standardized interface to automate the game.

## Initialization
To use the API in your custom client wrapper (like `air-aqw-enhanced`), you must pass the loaded `game.swf` MovieClip to the initialization function:

```as3
import com.aqwapi.AqwApi;

// Assuming `gameMC` is the loaded game.swf MovieClip:
AqwApi.init(gameMC);
```
Once initialized, the API will automatically bind to the game's internal data structures (Quests, Inventory, World, Combat).

## Combat System & Class Skills

The combat engine (`CombatManager`) is a highly advanced, 100% Skua-compatible engine. It operates entirely on Skua's `AdvancedSkills.json` dynamic configuration format.

### The AdvancedSkills.json System
Instead of hardcoding class combos, the API relies on an external `AdvancedSkills.json` file. This file uses a complex object structure containing multiple "Modes" (e.g., `Base`, `Farm`, `Solo`, `Supp`, `Atk`) for every single class. 

The API's combat engine natively understands and executes Skua's complex skill mechanics, including:
1. **Engine Types:**
   - `UseIfAvailable`: A priority-based spam engine. It will mash keys from top-to-bottom as fast as they come off cooldown.
   - `WaitForCooldown`: A strict sequence engine. It will patiently wait for the next skill in a combo sequence to come off cooldown before casting it.
2. **Rules:**
   - **Health/Mana Checks:** It dynamically checks your (or your target's) HP/MP thresholds (e.g., "Only use skill 4 if Health < 50%").
   - **Auras:** It natively parses active buffs and debuffs via the game's raw `dataLeaf` properties. (e.g., "Only use the Nuke skill if the monster currently has the *Righteous Seal* aura").

### Updating Class Logic
Because the API perfectly parses the Skua format, you never need to manually write combos. Whenever a new class is released, simply copy the latest `AdvancedSkills.json` from the open-source Skua repository directly into your client's `assets/` folder, and the API will immediately know how to play the class.

## Writing Scripts
For a complete list of commands available to write automated `.txt` scripts (like `JOIN`, `KILL`, `IFQUEST`, etc.), please see [SCRIPTING.md](SCRIPTING.md).

## Event Driven Architecture (Custom UI Notifications)
Because the API is completely decoupled from any specific user interface, it broadcasts events through a central dispatcher whenever an important action occurs (like combat starting, scripts finishing, or API logs). 

If you are a developer building a custom wrapper or UI (like a Material Design frontend), you can listen to these events to display your own tooltips, snackbars, or UI notifications without modifying the core API:

```as3
import com.aqwapi.AqwApi;
import com.aqwapi.events.ApiEvent;

// Listen for API notifications to bind to your own custom UI
AqwApi.dispatcher.addEventListener(ApiEvent.NOTIFICATION, onApiNotification);
AqwApi.dispatcher.addEventListener(ApiEvent.COMBAT_TOGGLED, onApiNotification);
AqwApi.dispatcher.addEventListener(ApiEvent.SCRIPT_STOPPED, onApiNotification);

function onApiNotification(e:ApiEvent):void {
    // Instead of game chat, display this in your Material UI Snackbar!
    myMaterialSnackbar.show(e.message);
}
```
