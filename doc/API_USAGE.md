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

The combat engine (`CombatManager`) operates entirely on a dynamic JSON configuration for class skill rotations, allowing updates without needing to recompile the API or the game client.

### Where is `skills.json` loaded from?

The Combat Manager uses a smart-merge feature. It reads the files in this order:

1. **User Custom File (Editable):** `skills_custom.json` (located in the application's root directory, right next to the executable/launcher)
2. **Bundled Assets (Fallback):** `assets/skills.json` (compiled inside your application's assets folder)

If the file does not exist in the root directory, the API will automatically copy the bundled asset to `skills_custom.json` in the root, allowing end-users to easily open the JSON file in any text editor and customize their class rotations.

### Where to get `skills.json`?
Since the API no longer hardcodes class skills, you must provide a `skills.json` file in your client's `assets/` directory. 

**Format:** The file must be a JSON dictionary mapping lowercase class names to an array of skill indices (1-5).
```json
{
    "archmage": [2, 5, 3, 4, 1],
    "void highlord": [3, 4, 5, 2, 1],
    "legion revenant": [4, 2, 3, 5, 1]
}
```

*Note: For a fully up-to-date repository of class rotations, you can periodically reference the open-source `AdvancedSkills.json` from the Skua bot repository and adapt it to this clean array format. A default `skills.json` is shipped with the front-end client build.*

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
