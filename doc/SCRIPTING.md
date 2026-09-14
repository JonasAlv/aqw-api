# Scripting Guide for AQW-API

The AQW-API Script Manager reads custom line-by-line `.txt` scripts to automate game actions. 
The syntax generally follows the format: `ACTION arg1, arg2, arg3`.

## Navigation & Flow Control
- **`JOIN mapname, cell, pad`**: Joins a specific map and cell (e.g., `JOIN mobius, Enter, Spawn`). *Note: This automatically drops your combat state before jumping to prevent errors.*
- **`DELAY ms`**: Pauses the script for the specified milliseconds (e.g., `DELAY 2000` for 2 seconds).
- **`LABEL name`**: Marks a specific line in the script with a label.
- **`GOTO name`**: Jumps script execution to the specified `LABEL`.

## Combat Automation
- **`KILL monster_name, item_name, quantity, mmid`**: Safely kills a specific monster in the map until you collect the required quantity of the specified drop. The bot automatically handles whitelisting and auto-accepting drops. 
   - **`mmid` (Optional)**: If you are fighting monsters that share the exact same name but drop different items (e.g., *Tsukumo-gami*), specify the exact Monster Map ID (mmid) as the 4th parameter.

*(Combat classes and skill rotations are automatically managed by the `AdvancedSkills.json` configuration file, running your optimal combo in the background).*

## Advanced Questing
The API provides advanced quest caching and conditional branching for smart saga scripts.

- **`LOADQUEST id1, id2, id3...`**: Loads quests into the game's memory cache. You can pass a single ID or a comma-separated list to batch-load an entire saga at the start of your script.
- **`ACCEPT quest_id`**: Accepts a loaded quest.
- **`COMPLETE quest_id`** or **`COMPLETE quest_id:reward_id`**: Turns in the quest. If the quest has a specific reward choice, append it using a colon (e.g., `COMPLETE 245:1020` to choose reward item 1020).
- **`IFQUEST quest_id`**: Checks if the specified quest is already complete (in the server's quest tree). If true, it executes the immediate next line. If false, it skips the next line.
- **`IFNOTQUEST quest_id`**: The reverse of `IFQUEST`.
- **`GETMAPITEM id, quantity`**: Collects a map-specific quest item (the glowing blue nodes). **Note: You must use the raw numeric Map Item ID (e.g., `GETMAPITEM 42, 1`), not the item's string name.**

**Example of a Smart Saga Script:**
```text
// Batch load all quests at the start
LOADQUEST 245, 246

// 1. Winged Spies
IFQUEST 245
GOTO skip_quest_245
ACCEPT 245
KILL Chaos Sp-Eye, Eyeball Wings, 5
COMPLETE 245
LABEL skip_quest_245

// 2. Chaos Prisoners
IFQUEST 246
GOTO skip_quest_246
ACCEPT 246
GETMAPITEM 42, 5
COMPLETE 246
LABEL skip_quest_246
```

### Breakdown of the Smart Saga Script:
Here is exactly what the code above is doing under the hood:
1. **`LOADQUEST 245, 246`**: The bot sends a single, highly-optimized network packet to the server to pre-load all the quests in this saga. This prevents the bot from lagging mid-combat later.
2. **`IFQUEST 245`**: The bot checks the server data to see if you have *already completed* "Winged Spies".
   * **If YES:** It runs the immediate next line (`GOTO skip_quest_245`), jumping the bot safely past the entire combat block.
   * **If NO:** It ignores the `GOTO` line and proceeds downward to actually do the quest!
3. **`ACCEPT 245`**: Accepts the quest. (The API automatically syncs safe network delays here).
4. **`KILL ...`**: Runs the custom combat rotation in the background, farming the monsters until 5 "Eyeball Wings" drop.
5. **`COMPLETE 245`**: Safely turns in the quest.
6. **`LABEL skip_quest_245`**: This is just an invisible marker. When the `GOTO` command triggers, this is where the script lands so it can continue with the next quest ("Chaos Prisoners").

## Inventory and Shops
You can automate complex inventory management and shopping using the following commands:
- **`BANK item_name`**
- **`UNBANK item_name`**
- **`LOADSHOP shop_id`**
- **`BUY item_name`**
- **`SELL item_name`**
- **`EQUIP item_name`**

*(Note: Unlike older bots, you **do not** need to manually add `DELAY` timers between every single inventory/shop command. The API has built-in smart delays to ensure safe packet sync with the server.)*
