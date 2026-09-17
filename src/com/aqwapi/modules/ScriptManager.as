package com.aqwapi.modules {
	import com.aqwapi.events.ApiEvent;
	import com.aqwapi.utils.ApiLogger;
	import com.aqwapi.data.EntityDTO;
	import com.aqwapi.AqwApi;
	import com.aqwapi.commands.ScriptCommands;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class ScriptManager {
		private var _timer:Timer;
		public var commands:Array = [];
		public var currentIndex:int = 0;
		public var isRunning:Boolean = false;
		public var waitTimer:Number = 0;
		public var labels:Object = {};
		public var unbankedItems:Object = {};
		public var completedThisSession:Object = {}; // tracks quests completed in this bot run
		public var statusText:String = "Stopped";
		
		private static var _instance:ScriptManager;
		public static function get SINGLETON():ScriptManager {
			if (_instance == null) {
				_instance = new ScriptManager();
			}
			return _instance;
		}

		public function ScriptManager() {
			_timer = new Timer(500); // Check every 500ms
			_timer.addEventListener(TimerEvent.TIMER, onTick, false, 0, true);
		}

		public function loadScript(scriptText:String):void {
			if (!AqwApi.isReady && com.aqwapi.AqwApi.game != null) {
				AqwApi.init(com.aqwapi.AqwApi.game);
			}
			if (AqwApi.isReady) {
				AqwApi.drops.start();
			}
			
			commands = [];
			currentIndex = 0;
			unbankedItems = {};
			
			scriptText = scriptText.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
			var lines:Array = scriptText.split("\n");
			for (var i:int = 0; i < lines.length; i++) {
				var line:String = lines[i].replace(/^\s+|\s+$/g, "");
				if (line.length == 0 || line.indexOf("//") == 0 || line.indexOf("--") == 0) {
					continue;
				}
				
				var firstSpace:int = line.indexOf(" ");
				var action:String = line;
				var argsString:String = "";
				if (firstSpace != -1) {
					action = line.substring(0, firstSpace);
					argsString = line.substring(firstSpace + 1).replace(/^\s+|\s+$/g, "");
				}
				
				var args:Array = [];
				if (argsString.length > 0) {
					var rawArgs:Array = argsString.split(",");
					for (var a:int = 0; a < rawArgs.length; a++) {
						args.push(String(rawArgs[a]).replace(/^\s+|\s+$/g, ""));
					}
					for (var j:int = 0; j < args.length; j++) {
						args[j] = args[j].replace(/^\s+|\s+$/g, "");
					}
				}
				
				commands.push({ action: action.toUpperCase(), args: args, raw: line });
			}
			reset();
			statusText = "Loaded " + commands.length + " commands.";
		}

		public function reset():void {
			currentIndex = 0;
			waitTimer = 0;
			
			labels = {};
			for (var k:int = 0; k < commands.length; k++) {
				if (commands[k].action == "LABEL" && commands[k].args.length > 0) {
					labels[commands[k].args[0].toLowerCase()] = k;
				}
			}
			
			unbankedItems = {};
			completedThisSession = {};

			statusText = "Stopped";
		}
		
		public function start():void {
			if (!com.aqwapi.AqwApi.isReady) com.aqwapi.AqwApi.init(com.aqwapi.AqwApi.game);
			if (commands.length == 0) return;
			
			if (currentIndex >= commands.length) {
				currentIndex = 0;
				unbankedItems = {};
				completedThisSession = {};
			}
			isRunning = true;
			waitTimer = 0;
			
			// Initialize CombatManager and its JSON data
			CombatManager.init();

			if (CombatManager.IS_ON) {
								CombatManager.stop();
			}
			_timer.start();
			statusText = "Running...";
			ApiLogger.info("Script", "Script Started!");
			AqwApi.dispatcher.dispatchEvent(new ApiEvent(ApiEvent.SCRIPT_STARTED, "Script Started!"));
		}

		public function stop():void {
			var wasRunning:Boolean = isRunning;
			isRunning = false;
			_timer.stop();
			statusText = "Stopped.";
			if (AqwApi.isReady) {
				AqwApi.combat.stopAuto();
				AqwApi.quest.stopAuto();
			} else if (com.aqwapi.AqwApi.game != null) {
				CombatManager.stop();
				try {
					var world:* = com.aqwapi.AqwApi.game.world;
					if (world != null && world.moveToCell != null && world.strFrame != null && world.strPad != null) {
						world.moveToCell(world.strFrame, world.strPad);
					}
				} catch (e:Error) {}
			}
			if (wasRunning) {
				ApiLogger.info("Script", "Script Stopped!");
				AqwApi.dispatcher.dispatchEvent(new ApiEvent(ApiEvent.SCRIPT_STOPPED, "Script Stopped!"));
			}
		}

		public function getItemCount(searchName:String):int {
			return AqwApi.inventory.getQuestQuantity(searchName);
		}

		private function onTick(e:TimerEvent):void {
			if (!isRunning || !com.aqwapi.AqwApi.game || !com.aqwapi.AqwApi.game.world) return;
			var world:* = com.aqwapi.AqwApi.game.world;
			
			if (world.myAvatar != null && world.myAvatar.dataLeaf != null && world.myAvatar.dataLeaf.intState == 0) {
				statusText = "Waiting for respawn...";
				return;
			}
			
			if (currentIndex >= commands.length) {
				var bgCombat:Boolean = CombatManager.IS_ON;
				var bgQuest:Boolean = AqwApi.quest != null && AqwApi.quest.isAutoRunning;
				if (bgCombat || bgQuest) {
					statusText = bgCombat ? "Auto-combat running" : "Auto-quest running";
					waitTimer = getTimer() + 10000;
					return;
				}
				stop();
				statusText = "Script Finished!";
				ApiLogger.info("Script", "Script Finished!");
				AqwApi.dispatcher.dispatchEvent(new ApiEvent(ApiEvent.NOTIFICATION, "Script Finished!"));
				return;
			}
			
			var now:Number = getTimer();
			if (waitTimer > 0 && now < waitTimer) {
				return; // Still waiting
			}
			
			var cmd:Object = commands[currentIndex];

			ScriptCommands.execute(cmd, this);

		}

	}
}

// Helper to init AqwApi inside loadScript

