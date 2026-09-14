package com.aqwapi.modules {
	import com.aqwapi.events.ApiEvent;


	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import com.aqwapi.AqwApi;
	import com.aqwapi.data.EntityDTO;

	public class CombatManager {

		public  static var IS_ON:Boolean        = false;
		public  static var isSmart:Boolean      = false;
		public  static var lockedMMID:String    = null;
		public  static var targetName:String    = null;
		public  static var skillMode:String     = "Base";
		private static var _timer:Timer;
		private static var _customRotation:Array = [5,4,3,2,1];
		private static var _rotationIndex:int    = 0;
		private static var _skillsData:Object    = null;
		private static var _waitUntil:Object     = {};

		public static function init():void {
			reloadSkills();
		}

		public static function toggleSmart():void {
			if (IS_ON && isSmart) { stop(); return; }
			reloadSkills();
			start(true);
		}

		public static function toggleCustom():void {
			if (IS_ON && !isSmart) { stop(); return; }
			start(false);
		}

		public static function start(smart:Boolean, silent:Boolean = false):void {
			stop();
			reloadSkills(silent);
			isSmart = smart;
			IS_ON = true;
			_rotationIndex = 0;
			_waitUntil = {};
			
			if (lockedMMID == null && com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.world && com.aqwapi.AqwApi.game.world.myAvatar) {
				var avatar:* = com.aqwapi.AqwApi.game.world.myAvatar;
				if (avatar.target != null) {
					var mmidSrc:* = (avatar.target.dataLeaf != null) ? avatar.target.dataLeaf : (avatar.target.objData != null ? avatar.target.objData : null);
					if (mmidSrc != null && mmidSrc.MonMapID != null) lockedMMID = String(mmidSrc.MonMapID);
				}
			}
			
			com.aqwapi.AqwApi.dispatcher.dispatchEvent(new ApiEvent(ApiEvent.COMBAT_TOGGLED, isSmart ? "Smart Combat Activated" : "Custom Combat Activated"));
			if (!silent && com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) com.aqwapi.AqwApi.game.chatF.pushMsg("warning", isSmart ? "Smart Combat Activated" : "Custom Combat Activated", "SERVER", "", 0);
			if (_timer == null) {
				_timer = new Timer(500);
				_timer.addEventListener(TimerEvent.TIMER, onTick, false, 0, true);
			}
			_timer.start();
		}

		public static function stop():void {
			IS_ON = false;
			if (_timer != null) { _timer.stop(); _timer = null; }
			lockedMMID = null;
			targetName = null;
		}

		public static function setCustomRotation(rotation:Array):void {
			_customRotation = rotation;
		}

		public static function reloadSkills(silent:Boolean = false):void {
			try {
				var bundledFile:File = File.applicationDirectory.resolvePath("assets/AdvancedSkills.json");
				var stream:FileStream;
				var raw:String;

				// Always load the bundled assets/AdvancedSkills.json — works on ALL platforms
				// On Android this is inside the APK (read-only, always available)
				if (bundledFile.exists) {
					stream = new FileStream();
					stream.open(bundledFile, FileMode.READ);
					raw = stream.readUTFBytes(stream.bytesAvailable);
					stream.close();
					_skillsData = JSON.parse(raw);
				} else {
					_skillsData = {};
					if (!silent && com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) {
						com.aqwapi.AqwApi.game.chatF.pushMsg("server", "Warning: assets/AdvancedSkills.json missing!", "API", "", 0);
					}
				}

				// Optionally merge a skills_custom.json placed next to the exe
				// (On Android, this just safely checks the APK root where it won't exist)
				var customFile:File = File.applicationDirectory.resolvePath("skills_custom.json");
				
				if (customFile.exists) {
					try {
						stream = new FileStream();
						stream.open(customFile, FileMode.READ);
						raw = stream.readUTFBytes(stream.bytesAvailable);
						stream.close();
						var customData:Object = JSON.parse(raw);
						for (var key:String in customData) {
							_skillsData[key] = customData[key];
						}
						if (!silent && com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) {
							com.aqwapi.AqwApi.game.chatF.pushMsg("server", "Merged skills_custom.json override!", "API", "", 0);
						}
					} catch (ce:Error) {}
				}

			} catch (e:Error) {
				if (!silent && com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) {
					com.aqwapi.AqwApi.game.chatF.pushMsg("server", "AdvancedSkills.json error: " + e.message, "API", "", 0);
				}
			}
		}

		private static function onTick(e:TimerEvent):void {
			if (!com.aqwapi.AqwApi.game || !com.aqwapi.AqwApi.game.world || !com.aqwapi.AqwApi.game.world.myAvatar) return;

			var world:*  = com.aqwapi.AqwApi.game.world;
			var avatar:* = world.myAvatar;
			
			if (avatar.dataLeaf != null && avatar.dataLeaf.intState == 0) return;
			
			var target:* = avatar.target;

			if (target != null && target.dataLeaf != null && target.dataLeaf.intHP <= 0) {
				if (world.cancelTarget != null) world.cancelTarget();
				target = null;
			}

			if (target == null) {
				try {
					var currentMonsters:Array = AqwApi.monsters.getByCell(world.strFrame);
					for each (var monsterTarget:EntityDTO in currentMonsters) {
						if (monsterTarget == null || !monsterTarget.alive) continue;
						if (lockedMMID != null && monsterTarget.mapId != lockedMMID) continue;
						if (targetName != null && targetName != "*" && monsterTarget.name.toLowerCase().indexOf(targetName.toLowerCase()) == -1) continue;
						if (world.setTarget != null) { world.setTarget(monsterTarget.raw); target = monsterTarget.raw; break; }
					}
				} catch (err:Error) {}
			}

			if (target == null) return;

			if (world.approachTarget != null) {
				try {
					world.approachTarget();
				} catch (e:Error) {}
			}

			if (isSmart) {
				runAdvancedRotation(world, avatar, target);
			} else {
				runSimpleRotation(world, avatar);
			}
		}

		private static function runAdvancedRotation(world:*, avatar:*, target:*):void {
			var className:String = (avatar.objData && avatar.objData.strClassName) ? String(avatar.objData.strClassName) : "";
			var config:Object = findClassConfig(className);
			
			if (config == null) {
				runSimpleRotation(world, avatar);
				return;
			}
			
			// Skua AdvancedSkills.json support
			var modeConfig:Object = null;
			if (config[skillMode] != null) {
				modeConfig = config[skillMode];
			} else if (config["Base"] != null) {
				modeConfig = config["Base"];
			} else {
				// Fallback if neither mode exists but other modes do, pick first
				for (var key:String in config) {
					modeConfig = config[key];
					break;
				}
			}
			
			if (modeConfig == null || modeConfig.skills == null || !(modeConfig.skills is Array) || (modeConfig.skills as Array).length == 0) {
				runSimpleRotation(world, avatar);
				return;
			}
			
			var advancedSkills:Array = modeConfig.skills as Array;
			var useMode:String = modeConfig.skillUseMode != null ? String(modeConfig.skillUseMode) : "WaitForCooldown";
			
			if (useMode == "UseIfAvailable") {
				runUseIfAvailable(world, avatar, target, advancedSkills);
			} else {
				runWaitForCooldown(world, avatar, target, advancedSkills);
			}
		}

		private static function runWaitForCooldown(world:*, avatar:*, target:*, skills:Array):void {
			if (_rotationIndex >= skills.length) _rotationIndex = 0;
			var skill:Object = skills[_rotationIndex];
			var skillId:int  = skill.skillId + 1; // Map Skua's 0-5 to in-game 1-6

			if (!evaluateRules(skill.rules, world, avatar, target, skillId)) {
				_rotationIndex = (_rotationIndex + 1) % skills.length;
				return;
			}
			if (tryFireSkill(world, avatar, skillId)) {
				_rotationIndex = (_rotationIndex + 1) % skills.length;
			}
		}

		private static function runUseIfAvailable(world:*, avatar:*, target:*, skills:Array):void {
			for (var i:int = 0; i < skills.length; i++) {
				var skill:Object = skills[i];
				var skillId:int  = skill.skillId + 1; // Map Skua's 0-5 to in-game 1-6
				if (!evaluateRules(skill.rules, world, avatar, target, skillId)) continue;
				if (tryFireSkill(world, avatar, skillId)) return;
			}
		}

		private static function evaluateRules(rules:*, world:*, avatar:*, target:*, skillId:int):Boolean {
			if (rules == null) return true;
			var arr:Array = rules as Array;
			if (arr == null || arr.length == 0) return true;
			var pStats:* = getPlayerStats(world, avatar);
			for each (var rule:Object in arr) {
				if (!evaluateRule(rule, world, avatar, target, pStats, skillId)) return false;
			}
			return true;
		}

		private static function evaluateRule(rule:Object, world:*, avatar:*, target:*, pStats:*, skillId:int):Boolean {
			switch (String(rule.type)) {
				case "None": return true;

				case "Wait":
					var wKey:String  = "s" + skillId;
					var now:Number   = getTimer();
					var timeout:Number = rule.timeout || 0;
					if (_waitUntil[wKey] == null || now >= _waitUntil[wKey]) {
						_waitUntil[wKey] = now + timeout;
						return now >= (_waitUntil[wKey] - timeout);
					}
					return false;

				case "Health":
					var hp:Number    = getStat(pStats, avatar, "HP");
					var maxHp:Number = getStat(pStats, avatar, "MaxHP");
					var hpPct:Number = rule.isPercentage ? (maxHp > 0 ? hp / maxHp * 100 : 0) : hp;
					return compare(hpPct, rule.value, rule.comparison);

				case "Mana":
					var mp:Number    = getStat(pStats, avatar, "MP");
					var maxMp:Number = getStat(pStats, avatar, "MaxMP");
					var mpPct:Number = rule.isPercentage ? (maxMp > 0 ? mp / maxMp * 100 : 0) : mp;
					return compare(mpPct, rule.value, rule.comparison);

				case "Aura":
				case "MultiAura":
					var hasAura:Boolean = checkAura(rule.auraName, rule.auraTarget, world, avatar, target);
					return rule.comparison == "greater" ? hasAura : !hasAura;
			}
			return true;
		}

		private static function compare(val:Number, threshold:Number, comp:String):Boolean {
			return comp == "greater" ? val > threshold : val < threshold;
		}

		private static function getPlayerStats(world:*, avatar:*):* {
			try { if (world.uoTreeLeaf != null && avatar.pnm != null) return world.uoTreeLeaf(avatar.pnm); } catch (e:Error) {}
			return null;
		}

		private static function getStat(pStats:*, avatar:*, stat:String):Number {
			var dl:* = avatar.dataLeaf;
			switch (stat) {
				case "HP":    return pStats && pStats.intHP    != null ? pStats.intHP    : (dl ? dl.intHP    : 0);
				case "MaxHP": return pStats && pStats.intHPMax != null ? pStats.intHPMax : (dl ? dl.intHPMax : 1);
				case "MP":    return pStats && pStats.intMP    != null ? pStats.intMP    : (dl ? dl.intMP    : 0);
				case "MaxMP": return pStats && pStats.intMPMax != null ? pStats.intMPMax : (dl ? dl.intMPMax : 1);
			}
			return 0;
		}

		private static function checkAura(auraName:String, auraTarget:String, world:*, avatar:*, target:*):Boolean {
			var auras:* = null;
			if (auraTarget == "self") {
				try { if (world.uoTreeLeaf && avatar.pnm) { var n:* = world.uoTreeLeaf(avatar.pnm); if (n && n.auras) auras = n.auras; } } catch (e:Error) {}
				if (auras == null && avatar.auras) auras = avatar.auras;
			} else {
				if (target && target.dataLeaf && target.dataLeaf.auras) auras = target.dataLeaf.auras;
			}
			if (auras == null) return false;
			var search:String = auraName.toLowerCase();
				if (auras is Array) {
					for each (var a:* in auras) { 
						if (a && a.name && String(a.name).toLowerCase() == search) return true; 
						if (a && a.nam && String(a.nam).toLowerCase() == search) return true; 
					}
				} else {
					for (var k:String in auras) { 
						var av:* = auras[k]; 
						if (av && av.name && String(av.name).toLowerCase() == search) return true; 
						if (av && av.nam && String(av.nam).toLowerCase() == search) return true; 
					}
				}
			return false;
		}

		private static function findClassConfig(className:String):Object {
			if (_skillsData == null) init();
			if (_skillsData == null || className == "") return null;
			var lower:String = className.toLowerCase();
			for (var key:String in _skillsData) { if (key.toLowerCase() == lower) return _skillsData[key]; }
			return null;
		}

		public static function getAvailableModes(className:String):Array {
			var config:Object = findClassConfig(className);
			if (config == null) return ["Base"];
			if (config is Array) return ["Base"];
			
			var modes:Array = [];
			for (var mode:String in config) {
				modes.push(mode);
			}
			if (modes.length == 0) return ["Base"];
			return modes;
		}

		private static function runSimpleRotation(world:*, avatar:*):void {
			var valid:Array = [];
			for each (var idx:int in _customRotation) {
				var icon:* = getIcon(idx);
				if (icon && icon.actObj && icon.actObj.isOK !== false) valid.push(idx);
			}
			if (valid.length == 0) return;
			if (_rotationIndex >= valid.length) _rotationIndex = 0;
			if (tryFireSkill(world, avatar, valid[_rotationIndex])) _rotationIndex = (_rotationIndex + 1) % valid.length;
		}

		private static function tryFireSkill(world:*, avatar:*, idx:int):Boolean {
			var icon:* = getIcon(idx);
			if (!icon || !icon.actObj || icon.actObj.isOK === false) return false;
			var pStats:* = getPlayerStats(world, avatar);
			var dl:*     = avatar.dataLeaf;
			
			if (dl && dl.intState == 0) return false;

			var mpCost:int  = icon.actObj.mp != null ? parseInt(icon.actObj.mp) : 0;
			var curMp:int   = pStats && pStats.intMP != null ? pStats.intMP : (dl ? dl.intMP : 0);
			if (curMp < mpCost) return false;
			var hpCost:int  = icon.actObj.hp != null ? parseInt(icon.actObj.hp) : 0;
			var curHp:int   = pStats && pStats.intHP != null ? pStats.intHP : (dl ? dl.intHP : 0);
			if (hpCost > 0 && curHp <= hpCost) return false;
			var ready:Boolean = world.actionTimeCheck != null ? world.actionTimeCheck(icon.actObj) : true;
			if (!ready) {
				try {
					if (world.ActionResults && world.ActionResults[icon.actObj.ref] != null) {
						ready = (new Date().getTime() - world.ActionResults[icon.actObj.ref].ts) >= icon.actObj.cd;
					}
				} catch (e:Error) {
					// Ignore coercion errors on modern clients where ActionResults is a Vector
				}
			}
			if (ready) { world.testAction(icon.actObj); return true; }
			return false;
		}

		private static function getIcon(idx:int):* {
			if (!com.aqwapi.AqwApi.game || !com.aqwapi.AqwApi.game.ui || !com.aqwapi.AqwApi.game.ui.mcInterface || !com.aqwapi.AqwApi.game.ui.mcInterface.actBar) return null;
			return com.aqwapi.AqwApi.game.ui.mcInterface.actBar.getChildByName("i" + idx);
		}
	}
}
