package com.aqwapi.commands {
	import com.aqwapi.AqwApi;
		import com.aqwapi.data.EntityDTO;
	import com.aqwapi.modules.ScriptManager;
	import com.aqwapi.modules.CombatManager;
	import com.aqwapi.events.ApiEvent;

	public class ScriptCommands {

		public static function execute(cmd:Object, manager:ScriptManager):void {
			var methodName:String = "cmd_" + cmd.action.toLowerCase();
			if (ScriptCommands.hasOwnProperty(methodName)) {
				ScriptCommands[methodName](cmd, manager);
			} else {
				trace("Unknown command: " + cmd.action);
				manager.currentIndex++;
			}
		}

		public static function cmd_join(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
					if (cmd.args.length >= 1) {
						var mapName:String = cmd.args[0];
						var cell:String = cmd.args.length >= 2 ? cmd.args[1] : "Enter";
						var pad:String = cmd.args.length >= 3 ? cmd.args[2] : "Spawn";
						
						manager.statusText = "Joining " + mapName + "...";
						AqwApi.map.join(mapName, cell, pad);
						manager.waitTimer = now + 4000;
					}
					manager.currentIndex++;
					return;
						
		}

		public static function cmd_reload(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
					manager.statusText = "Reloading Zone...";
					AqwApi.combat.dropCombat();
					manager.waitTimer = now + 1000;
					manager.currentIndex++;
					return;
		}

		public static function cmd_loadquest(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var qids:Array = [];
							for (var i:int = 0; i < cmd.args.length; i++) {
								qids.push(parseInt(cmd.args[i]));
							}
							manager.statusText = "Loading Quests: " + qids.join(",");
							if (com.aqwapi.AqwApi.game != null && com.aqwapi.AqwApi.game.world != null && com.aqwapi.AqwApi.game.world.getQuests != null) {
								com.aqwapi.AqwApi.game.world.getQuests(qids);
							}
							manager.waitTimer = now + 1500; // In a full implementation, wait for QUEST_UPDATED event
							manager.currentIndex++;
						}
						return;

		}

		public static function cmd_getmapitem(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						// GETMAPITEM <itemID>, <qty>
						// Sends getMapItem packet qty times with 1.5s between each
						// Used for map item quests (no combat required)
						if (cmd.args.length >= 1 && com.aqwapi.AqwApi.game != null && com.aqwapi.AqwApi.game.sfc != null) {
							var mapItemID:int = parseInt(cmd.args[0]);
							var mapItemQty:int = cmd.args.length >= 2 ? parseInt(cmd.args[1]) : 1;
							if (cmd.gmiCount == null) cmd.gmiCount = 0;
							if (cmd.gmiCount < mapItemQty) {
								AqwApi.map.getMapItem(mapItemID);
								cmd.gmiCount++;
								manager.statusText = "GetMapItem " + mapItemID + " (" + cmd.gmiCount + "/" + mapItemQty + ")";
								manager.waitTimer = now + 1500;
							} else {
								manager.currentIndex++;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_accept(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
			
			if (cmd.args.length >= 1) {
				qid = parseInt(cmd.args[0]);
				manager.statusText = "Accepting Quest " + qid;
				
				var inProgress:Boolean = false;
				if (world.isQuestInProgress != null && world.isQuestInProgress(qid)) {
					inProgress = true;
				}
				
				if (!inProgress) {
					if (cmd.acceptTimer == null) {
						// First time
						cmd.acceptTimer = now;
						AqwApi.quest.accept(qid);
						return; // Wait for next tick
					} else if (now - cmd.acceptTimer < 3000) {
						// Still waiting for server
						return;
					} else {
						// Timeout - failed to accept (probably one-time/daily done)
						if (com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) com.aqwapi.AqwApi.game.chatF.pushMsg("warning", "Quest " + qid + " failed to accept! Skipping...", "API", "", 0);
						
						var completeIdx:int = -1;
						for (var i:int = manager.currentIndex + 1; i < manager.commands.length; i++) {
							var futureCmd:Object = manager.commands[i];
							if (futureCmd.action == "COMPLETE" && futureCmd.args.length >= 1 && parseInt(futureCmd.args[0]) == qid) {
								completeIdx = i;
								break;
							}
						}
						
						if (completeIdx != -1) {
							manager.currentIndex = completeIdx + 1; // Skip past the complete
						} else {
							manager.currentIndex++;
						}
						
						cmd.acceptTimer = null;
						return;
					}
				}
				
				// Reached here means inProgress is true
				cmd.acceptTimer = null;
				manager.currentIndex++;
			}
		}
		public static function cmd_complete(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var cqid:int = parseInt(cmd.args[0]);
							manager.statusText = "Completing Quest " + cqid;
							AqwApi.quest.complete(cqid);
							// Mark in our local tracker so IFQUEST knows it was attempted
							manager.completedThisSession[cqid] = true;
							manager.waitTimer = now + 2000;
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_equip(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var equipName:String = cmd.args.join(", ").toLowerCase();
							manager.statusText = "Equipping: " + equipName;
							AqwApi.inventory.equip(equipName);
							manager.waitTimer = now + 1500;
							manager.currentIndex++;
						}
						return;

		}

		public static function cmd_equipclass(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
			if (cmd.args.length >= 1) {
				var lType:String = cmd.args[0].toLowerCase();
				manager.statusText = "Equipping Loadout: " + lType;
				AqwApi.combat.dropCombat();
				AqwApi.combat.equipLoadout(lType);
				manager.waitTimer = now + 3000;
				manager.currentIndex++;
			} else {
				if (com.aqwapi.AqwApi.game != null && com.aqwapi.AqwApi.game.chatF != null) {
					com.aqwapi.AqwApi.game.chatF.pushMsg("server", "Invalid EQUIPCLASS command syntax. Use Farm, Solo, Boss, or Dodge.", "API", "", 0);
				}
				manager.currentIndex++;
			}
			return;
		}

		public static function cmd_bank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var bankName:String = cmd.args.join(", ").toLowerCase();
							manager.statusText = "Banking: " + bankName;
							AqwApi.inventory.bank(bankName);
							manager.waitTimer = now + 1500;
							manager.currentIndex++;
						}
						return;
						


		}

		public static function cmd_unbank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var unbankName:String = cmd.args.join(", ").toLowerCase();
							manager.statusText = "Unbanking: " + unbankName;
							AqwApi.inventory.unbank(unbankName);
							manager.waitTimer = now + 1500;
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_kill(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
					if (cmd.args.length >= 3) {
						var monster:String = cmd.args[0];
						var itemName:String = cmd.args[1];
						var qty:int = parseInt(cmd.args[2]);
						var mmid:String = (cmd.args.length >= 4) ? cmd.args[3] : null;
						
						manager.statusText = "Hunting " + monster + " for " + itemName + " (" + qty + ")";
							var currentQty:int = AqwApi.inventory.getQuestQuantity(itemName);
							
							var targetDrops:Array = itemName.toLowerCase().split("|");
							AqwApi.drops.targetDrops = targetDrops;
							
							if (cmd.lastQty !== currentQty) {
								cmd.lastQty = currentQty;
								com.aqwapi.AqwApi.dispatcher.dispatchEvent(new ApiEvent(
									ApiEvent.STICKY_NOTIFICATION, 
									"Farming " + monster + " for " + itemName + " " + currentQty + "/" + qty, 
									{ id: "farming_status" }
								));
							}
							
							if (currentQty >= qty) {
								// Done - stop combat and advance
								com.aqwapi.AqwApi.dispatcher.dispatchEvent(new ApiEvent(
									ApiEvent.REMOVE_STICKY, 
									"", 
									{ id: "farming_status" }
								));
								AqwApi.drops.targetDrops = [];
								if (CombatManager.IS_ON) CombatManager.stop();
								manager.currentIndex++;
							} else {
								// Still need items - show progress
							
							// Auto-pickup if the items we are farming dropped as real (non-temp) items
							// Supports multiple items separated by '|' (e.g., "Bone Dust|Undead Essence")
							AqwApi.drops.acceptPendingDrops(targetDrops);

								if (cmd.lockedCell == null) {
									var initialTarget:EntityDTO = mmid != null ? AqwApi.monsters.findByMapId(mmid, true) : AqwApi.monsters.findByName(monster, true);
									trace("[ScriptManager.KILL] Alive lookup for " + monster + ": " + (initialTarget != null ? initialTarget.cell : "null"));
									if (initialTarget == null) {
										initialTarget = mmid != null ? AqwApi.monsters.findByMapId(mmid, false) : AqwApi.monsters.findByName(monster, false);
										trace("[ScriptManager.KILL] Dead/Unknown lookup for " + monster + ": " + (initialTarget != null ? initialTarget.cell : "null"));
									}
									if (initialTarget != null) {
										cmd.lockedCell = initialTarget.cell;
										cmd.lockedMMID = initialTarget.mapId;
									}
								}
																var foundMMID:String = cmd.lockedMMID != null ? cmd.lockedMMID : mmid;
									var monCell:String = cmd.lockedCell;
									trace("[ScriptManager.KILL] monCell locked to: " + monCell);
									
									var target:EntityDTO = foundMMID != null ? AqwApi.monsters.findByMapId(foundMMID, false) : AqwApi.monsters.findByName(monster, false);
									var approachMon:* = target != null ? target.raw : null;
								
								if (monCell != null && world.strFrame != monCell && cmd.pendingTeleport == null) {
									// Cross-cell: jump first.
									AqwApi.map.jump(monCell, "Enter");
									cmd.pendingTeleport = monCell;
								cmd.teleportTimer = now + 1000; // Give the game a full second to load the cell
								manager.waitTimer = now + 1000;
							}
							
							if (cmd.pendingTeleport != null) {
								if (world.strFrame == cmd.pendingTeleport && now >= cmd.teleportTimer) {
									// Arrived and cell has fully loaded! Snap and start combat
																		CombatManager.start(true, true);
																		CombatManager.targetName = monster;
																		CombatManager.lockedMMID = (foundMMID != null) ? foundMMID : mmid;
									
									var cellMons:* = ("getMonstersByCell" in world) ? world.getMonstersByCell(world.strFrame) : world.monsters;
									for each (var cm:* in cellMons) {
										if (cm == null || cm.pMC == null) continue;
										var cmName:String = (cm.objData && cm.objData.strMonName) ? String(cm.objData.strMonName).toLowerCase() : null;
										var cmMMID:String = null;
										if (cm.dataLeaf && cm.dataLeaf.MonMapID) cmMMID = String(cm.dataLeaf.MonMapID);
										else if (cm.objData && cm.objData.MonMapID) cmMMID = String(cm.objData.MonMapID);
										var cmMatch:Boolean = CombatManager.lockedMMID != null ? (cmMMID == CombatManager.lockedMMID) : (monster == "*" || (cmName != null && cmName.indexOf(monster.toLowerCase()) != -1));
										if (cmMatch) {
											AqwApi.map.snapTo(cm);
											break;
										}
									}
									cmd.pendingTeleport = null;
									manager.waitTimer = now + 1000;
								} else {
									// Waiting for cell load and timer...
									manager.waitTimer = now;
								}
							} else if (!CombatManager.IS_ON && world.strFrame == monCell) {
								// We are in the correct cell (or couldn't find the cell yet). Start combat!
																CombatManager.start(true, true);
																CombatManager.targetName = monster;
																CombatManager.lockedMMID = (foundMMID != null) ? foundMMID : mmid;
								
								// Snap directly onto the mob
								AqwApi.map.snapTo(approachMon);
								manager.waitTimer = now + 1000;
							} else if (cmd.pendingTeleport == null && manager.waitTimer <= now) {
								manager.waitTimer = now + 1000;
							}
						}
						} else {
							if (com.aqwapi.AqwApi.game != null && com.aqwapi.AqwApi.game.chatF != null) {
								com.aqwapi.AqwApi.game.chatF.pushMsg("server", "Invalid KILL syntax. Use: KILL Monster Name, Item Name, Quantity", "API", "", 0);
							}
							manager.statusText = "KILL Syntax Error";
							manager.currentIndex++;
						}
						return;
						
		}


		public static function cmd_delay(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length > 0) {
							var ms:int = parseInt(cmd.args[0]);
							manager.waitTimer = now + ms;
							manager.statusText = "Waiting " + ms + "ms...";
						}
						manager.currentIndex++;
						return;
						

						
		}

		public static function cmd_getdrop(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
							if (cmd.args.length > 0 && world != null) {
								var dropTarget:String = cmd.args[0].toLowerCase();

								for (var di:int = AqwApi.drops.pendingDrops.length - 1; di >= 0; di--) {
									var pDrop:Object = AqwApi.drops.pendingDrops[di];
									if (dropTarget == "all" || pDrop.sName.toLowerCase() == dropTarget) {
										AqwApi.transport.sendExtensionCommand("getDrop", [pDrop.ItemID]);
// 										 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "GETDROP COMMAND: " + pDrop.sName, "SERVER", "", 0);
										AqwApi.drops.pendingDrops.splice(di, 1);
									}
								}
							}
							manager.currentIndex++;
							return;
		}

		public static function cmd_dump_drops(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (world != null) {
							var found:Boolean = false;
							if (world.items != null) {
								for (var i:int = 0; i < world.items.length; i++) {
									var itemObj:* = world.items[i];
									if (itemObj != null && itemObj.sName != null) {
										var sName:String = itemObj.sName.toLowerCase();
										if (sName.indexOf("essence") != -1 || sName.indexOf("bone") != -1) {
// 											 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "world.items HAS: " + itemObj.sName + " ID: " + itemObj.ItemID, "SERVER", "", 0);
											found = true;
										}
									}
								}
							}
							if (!found) {
// 								 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "Not found in world.items either!", "SERVER", "", 0);
							}
						}
						manager.currentIndex++;
						return;
		}

		public static function cmd_test_drop(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (world != null) {
							var found:Boolean = false;
							if (world.dropStack != null) {
								for (var i:int = 0; i < world.dropStack.length; i++) {
									var dropObj:* = world.dropStack[i];
// 									 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "DROP: " + dropObj.sName + " ID: " + dropObj.ItemID, "SERVER", "", 0);
									found = true;
								}
							}
							if (com.aqwapi.AqwApi.game.ui != null && com.aqwapi.AqwApi.game.ui.dropStack != null) {
								for (var j:int = 0; j < com.aqwapi.AqwApi.game.ui.dropStack.length; j++) {
									var uDrop:* = com.aqwapi.AqwApi.game.ui.dropStack[j];
// 									 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "UIDROP: " + uDrop.sName + " ID: " + uDrop.ItemID, "SERVER", "", 0);
									found = true;
								}
							}
							if (!found) {
// 								 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "NO DROPS FOUND IN dropStack or ui.dropStack", "SERVER", "", 0);
							}
						}
						manager.currentIndex++;
						return;
		}

		public static function cmd_log(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length > 0) {
							var msg:String = cmd.args.join(",");
							if (com.aqwapi.AqwApi.game != null) {
								if (com.aqwapi.AqwApi.game && com.aqwapi.AqwApi.game.chatF) com.aqwapi.AqwApi.game.chatF.pushMsg("warning", msg, "API", "", 0);
							}
							try {
								if (world != null && world.chatF != null) {
// 									 world.chatF.pushMsg ("server", msg, "API", "", 0);
								}
							} catch (e:Error) {}
							com.aqwapi.AqwApi.dispatcher.dispatchEvent(new ApiEvent(ApiEvent.NOTIFICATION, msg));
							manager.statusText = msg;
						}
						manager.currentIndex++;
						return;
						
		}

		public static function cmd_combat(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var combatArg:String = cmd.args[0].toLowerCase();
							if (combatArg == "stop") {
								CombatManager.stop();
								manager.statusText = "Combat stopped";
							} else if (combatArg == "smart") {
								CombatManager.start(true, true);
								manager.statusText = "Combat: Smart";
							} else if (combatArg == "custom") {
								var rotInts:Array = [];
								if (cmd.args.length >= 2) {
									var rotRaw:String = String(cmd.args[1]);
									if (rotRaw.indexOf(",") != -1) {
										var rotParts:Array = rotRaw.split(",");
										for each (var rp:String in rotParts) {
											var ri:int = parseInt(rp);
											if (!isNaN(ri) && ri > 0) rotInts.push(ri);
										}
									} else {
										for (var rci:int = 0; rci < rotRaw.length; rci++) {
											var rcVal:int = parseInt(rotRaw.charAt(rci));
											if (!isNaN(rcVal) && rcVal > 0) rotInts.push(rcVal);
										}
									}
									if (rotInts.length > 0) CombatManager.setCustomRotation(rotInts);
								}
								CombatManager.start(false, true);
								manager.statusText = rotInts.length > 0 ? "Combat: Custom [" + rotInts.join("-") + "]" : "Combat: Custom";
							}
							manager.currentIndex++;
						}
						return;

		}

		public static function cmd_autoquest(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							if (cmd.args[0].toLowerCase() == "stop") {
								AqwApi.quest.stopAuto();
								manager.statusText = "AutoQuest stopped";
							} else {
								var qStr:String = cmd.args.join(",");
								AqwApi.quest.startAuto(qStr);
								manager.statusText = "Background QuestManager: " + qStr;
							}
							manager.currentIndex++;
						}
						return;
		}

		public static function cmd_label(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						manager.currentIndex++;
						return;
						
		}

		public static function cmd_goto(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var labelName:String = cmd.args[0].toLowerCase();
							if (manager.labels.hasOwnProperty(labelName)) {
								manager.currentIndex = manager.labels[labelName];
							} else {
								manager.currentIndex++;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_ifhas(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var targetItemName2:String = cmd.args[0].toLowerCase();
							var targetQty:int = 1;
							if (cmd.args.length >= 2) {
								targetQty = parseInt(cmd.args[1]);
							}
							
							var itemQty:int = manager.getItemCount(targetItemName2);
							
							var hasCondition:Boolean = (itemQty >= targetQty);
							var isMet:Boolean = (cmd.action == "IFHAS") ? hasCondition : !hasCondition;
							
							if (isMet) {
								// Condition met, proceed to next line
								manager.currentIndex++;
							} else {
								// Condition not met, skip the next line
								manager.currentIndex += 2;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_ifnothas(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var targetItemName2:String = cmd.args[0].toLowerCase();
							var targetQty:int = 1;
							if (cmd.args.length >= 2) {
								targetQty = parseInt(cmd.args[1]);
							}
							
							var itemQty:int = manager.getItemCount(targetItemName2);
							
							var hasCondition:Boolean = (itemQty >= targetQty);
							var isMet:Boolean = (cmd.action == "IFHAS") ? hasCondition : !hasCondition;
							
							if (isMet) {
								// Condition met, proceed to next line
								manager.currentIndex++;
							} else {
								// Condition not met, skip the next line
								manager.currentIndex += 2;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_ifrank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 2) {
							var factionName:String = cmd.args[0].toLowerCase();
							var targetRank:int = parseInt(cmd.args[1]);
							
							var currentRank:int = 1;
							if (world.myAvatar != null && world.myAvatar.factions != null) {
								for (var fi:int = 0; fi < world.myAvatar.factions.length; fi++) {
									var fac:* = world.myAvatar.factions[fi];
									if (fac != null && fac.sName != null && fac.sName.toLowerCase() == factionName) {
										currentRank = parseInt(fac.iRank);
										break;
									}
								}
							}
							
							if (currentRank < targetRank) {
								manager.currentIndex += 2;
								return;
							}
						}
						manager.currentIndex++;
						return;
						
		}

		public static function cmd_ifnotrank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 2) {
							var factionNameNot:String = cmd.args[0].toLowerCase();
							var targetRankNot:int = parseInt(cmd.args[1]);
							
							var currentRankNot:int = 1;
							if (world.myAvatar != null && world.myAvatar.factions != null) {
								for (var fin:int = 0; fin < world.myAvatar.factions.length; fin++) {
									var facNot:* = world.myAvatar.factions[fin];
									if (facNot != null && facNot.sName != null && facNot.sName.toLowerCase() == factionNameNot) {
										currentRankNot = parseInt(facNot.iRank);
										break;
									}
								}
							}
							
							if (currentRankNot >= targetRankNot) {
								manager.currentIndex += 2;
								return;
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_ifquest(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
					if (cmd.args.length >= 1) {
						qid = parseInt(cmd.args[0]);
						var qslot:int = -1;
						var qval:int = -1;
						
						var isCompleted:Boolean = false;
						
						if (world != null && world.questTree != null && world.questTree[qid] != null) {
							qslot = world.questTree[qid].Slot;
							qval = world.questTree[qid].Value;
						}
						
						// Method 1: Local session tracking - set by COMPLETE when server confirms
						// This is the most reliable since WE control when we mark it done
						if (manager.completedThisSession[qid] == true) {
							isCompleted = true;
						}
						
						// Method 2: Slot-based check (server sends on login, updates on completion)
						// NOTE: We intentionally do NOT check questTree[id].bComplete because
						// the game client sets bComplete optimistically BEFORE server confirms,
						// causing false positives (bot skips to locked quests).
						if (!isCompleted && qslot >= 0) {
							try {
								if (world.getQuestValue != null) {
									var slotVal:* = world.getQuestValue(qslot);
									if (slotVal != null && int(slotVal) >= qval) {
										isCompleted = true;
									}
								}
							} catch(e2:Error) {}
							
							// Method 3: alternate slot storage
							try {
								if (!isCompleted && world.questSlots != null && world.questSlots[qslot] != null) {
									if (int(world.questSlots[qslot]) >= qval) {
										isCompleted = true;
									}
								}
							} catch(e3:Error) {}
						}
							// Method 4: Permanent story quest completion (sField + iIndex bitmask)
							if (!isCompleted && world != null && world.questTree != null && world.questTree[qid] != null) {
								var qData:Object = world.questTree[qid];
								if (qData.sField != null && qData.iIndex >= 0) {
									try {
										if (world.getAchievement != null) {
											var ach:int = world.getAchievement(qData.sField, qData.iIndex);
											if (ach != 0) {
												isCompleted = true;
											}
										}
									} catch(e4:Error) {}
								}
							}
							
						try {
							if (com.aqwapi.AqwApi.game != null && com.aqwapi.AqwApi.game.chatF != null) {
								if (isCompleted) {
									com.aqwapi.AqwApi.game.chatF.pushMsg("warning", "Quest " + qid + " is already completed! Skipping...", "API", "", 0);
								}
							}
						} catch(le:Error) {}
						
						if (!isCompleted) {
							manager.currentIndex += 2;
							return;
						}
					}
					manager.currentIndex++;
					return;

		}

		public static function cmd_ifnotquest(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var qidNot:int = parseInt(cmd.args[0]);
							var qslotNot:int = -1;
							var qvalNot:int = -1;
							
							var isCompletedNot:Boolean = false;
							if (qslotNot >= 0 && world.getQuestValue != null) {
								isCompletedNot = (world.getQuestValue(qslotNot) >= qvalNot);
							}
							
							if (isCompletedNot) {
								manager.currentIndex += 2;
								return;
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_skipcutscene(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (world != null && world.mcExtSWF != null && world.mcExtSWF.numChildren > 0) {
							var ext:* = world.mcExtSWF.getChildAt(0);
							if (ext != null && ext.hasOwnProperty("totalFrames") && ext.hasOwnProperty("currentFrame") && ext.hasOwnProperty("gotoAndPlay")) {
								var tf:int = ext.totalFrames;
								var cf:int = ext.currentFrame;
								if (tf > 2 && cf < tf - 2) {
									ext.gotoAndPlay(tf - 2);
								}
							} else {
								while (world.mcExtSWF.numChildren > 0) {
									world.mcExtSWF.removeChildAt(0);
								}
								if (world.showInterface != null) {
									world.showInterface();
								}
							}
						}
						manager.currentIndex++;
						return;

		}
		public static function cmd_ifgold(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var targetGold:int = parseInt(cmd.args[0]);
							var currentGold:int = 0;
							if (world.myAvatar != null && world.myAvatar.objData != null) {
								currentGold = parseInt(world.myAvatar.objData.intGold);
							}
							if (currentGold < targetGold) {
								manager.currentIndex += 2;
								return;
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_iflevel(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							var targetLevel:int = parseInt(cmd.args[0]);
							var currentLevel:int = 1;
							if (world.myAvatar != null && world.myAvatar.objData != null) {
								currentLevel = parseInt(world.myAvatar.objData.intLevel);
							}
							if (currentLevel < targetLevel) {
								manager.currentIndex += 2;
								return;
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_waitfor(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length > 0) {
							var waitTarget:String = cmd.args[0].toLowerCase();
							var foundDrop:Boolean = false;
							
							for (var pi:int = 0; pi < AqwApi.drops.pendingDrops.length; pi++) {
								var waitDrop:Object = AqwApi.drops.pendingDrops[pi];
								if (waitDrop.sName.toLowerCase() == waitTarget) {
									foundDrop = true;
									break;
								}
							}
							
							if (foundDrop) {
								manager.currentIndex++;
							} else {
								manager.statusText = "Waiting for drop: " + cmd.args[0];
								manager.waitTimer = now + 500;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						


		}

		public static function cmd_loadshop(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							AqwApi.shop.loadShop(parseInt(cmd.args[0]));
							manager.waitTimer = now + 2000;
						}
						manager.currentIndex++;
						return;
						
		}

		public static function cmd_buy(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							AqwApi.shop.buyItem(cmd.args.join(" "));
							manager.waitTimer = now + 2000;
						}
						manager.currentIndex++;
						return;
						
		}

		public static function cmd_sell(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
							AqwApi.shop.sellItem(cmd.args.join(" "));
							manager.waitTimer = now + 2000;
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_jump(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 2 && world != null && "moveToCell" in world) {
							world.moveToCell(cmd.args[0], cmd.args[1]);
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_mapdump(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						// Print all monsters on the map with name, MMID, and cell to chat
						if (world != null && world.monsters != null && com.aqwapi.AqwApi.game.chatF != null) {
// 							 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "[MAPDUMP] map=" + world.strMapName + " cell=" + world.strFrame, "API", "", 0);
							for each (var dumpMon:* in world.monsters) {
								if (dumpMon == null) continue;
								var dumpName:String = "?";
								var dumpMMID:String = "?";
								var dumpCell:String = "?";
								if (dumpMon.objData != null && dumpMon.objData.strMonName != null) dumpName = String(dumpMon.objData.strMonName);
								if (dumpMon.dataLeaf != null && dumpMon.dataLeaf.MonMapID != null) dumpMMID = String(dumpMon.dataLeaf.MonMapID);
								else if (dumpMon.objData != null && dumpMon.objData.MonMapID != null) dumpMMID = String(dumpMon.objData.MonMapID);
																if (dumpMon.strFrame != null) dumpCell = String(dumpMon.strFrame);
// 								 com.aqwapi.AqwApi.game.chatF.pushMsg ("server", "  MON name=" + dumpName + " mmid=" + dumpMMID + " cell=" + dumpCell, "API", "", 0);
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_jumptommid(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1 && world != null && world.monsters != null) {
							var targetMMID:String = cmd.args[0];
							var foundFrame:String = null;
							for each (var hm:* in world.monsters) {
								if (hm != null) {
									var tmpMMID:String = null;
									if (hm.dataLeaf != null && hm.dataLeaf.MonMapID != null) {
										tmpMMID = String(hm.dataLeaf.MonMapID);
									} else if (hm.objData != null && hm.objData.MonMapID != null) {
										tmpMMID = String(hm.objData.MonMapID);
									}
									if (tmpMMID == targetMMID) {
										if (hm.pMC != null && hm.pMC.strFrame != null) {
											foundFrame = hm.pMC.strFrame;
										} else if (hm.strFrame != null) {
											foundFrame = hm.strFrame;
										} else if (hm.objData != null && hm.objData.strFrame != null) {
											foundFrame = hm.objData.strFrame;
										}
										break;
									}
								}
							}
							if (foundFrame != null && "moveToCell" in world) {
								world.moveToCell(foundFrame, "Enter");
							} else {
								manager.statusText = "MMID " + targetMMID + " not found!";
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_jumptomob(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						// Jump to the cell of a named monster: JUMPTOMOB Chaos Sp-Eye
						if (cmd.args.length >= 1) {
							var mobTarget:EntityDTO = AqwApi.monsters.findByName(cmd.args[0], true);
							if (mobTarget == null) mobTarget = AqwApi.monsters.findByName(cmd.args[0], false);
							
							if (mobTarget != null && mobTarget.cell != null) {
								AqwApi.map.jump(mobTarget.cell, "Enter");
							} else {
								manager.statusText = "Mob '" + cmd.args[0] + "' not found on map!";
							}
						}
						manager.currentIndex++;
						return;

		}

		public static function cmd_loadbank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.requested == null) {
							cmd.requested = true;
							if (world != null) {
								if (("loadBank" in world) && world.loadBank != null) {
									world.loadBank();
								} else if (world.sfc != null) {
									com.aqwapi.AqwApi.game.sfc.sendString("%xt%zm%loadBank%" + world.curRoom + "%All%");
								}
							}
							manager.waitTimer = now + 1000;
						} else {
							if (world != null && ((world.bankinfo != null && world.bankinfo.items != null) || world.bankTree != null)) {
								manager.currentIndex++;
							} else {
								manager.statusText = "Waiting for bank to load...";
								manager.waitTimer = now + 1000;
							}
						}
						return;
						
		}

		public static function cmd_manual_unbank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
														var actionIsBank:Boolean = (cmd.action == "MANUAL_BANK");
							var targetItemName:String = cmd.args[0].toLowerCase();
							
							var hasInInv:Boolean = false;
							if (world.invTree != null) {
								for (var m_ik:String in world.invTree) {
									var m_iObj:* = world.invTree[m_ik];
									if (m_iObj != null && m_iObj.sName != null && m_iObj.sName.toLowerCase() == targetItemName) {
										hasInInv = true;
										break;
									}
								}
							}
							
							var isSatisfied:Boolean = actionIsBank ? !hasInInv : hasInInv;
							
							if (isSatisfied) {
									manager.currentIndex++;
								} else {
								if (cmd.requested == null) {
									cmd.requested = true;
									if (("toggleBank" in world) && world.toggleBank != null) {
										world.toggleBank();
									}
									if (com.aqwapi.AqwApi.game != null) {
										}
								}
								manager.statusText = "MANUAL ACTION: Please " + (actionIsBank ? "BANK" : "UNBANK") + " " + cmd.args[0];
								manager.waitTimer = now + 1000;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}

		public static function cmd_manual_bank(cmd:Object, manager:ScriptManager):void {
			var world:* = com.aqwapi.AqwApi.game.world;
			var now:Number = new Date().getTime();
			var qid:int;
						if (cmd.args.length >= 1) {
														var actionIsBank:Boolean = (cmd.action == "MANUAL_BANK");
							var targetItemName:String = cmd.args[0].toLowerCase();
							
							var hasInInv:Boolean = false;
							if (world.invTree != null) {
								for (var m_ik:String in world.invTree) {
									var m_iObj:* = world.invTree[m_ik];
									if (m_iObj != null && m_iObj.sName != null && m_iObj.sName.toLowerCase() == targetItemName) {
										hasInInv = true;
										break;
									}
								}
							}
							
							var isSatisfied:Boolean = actionIsBank ? !hasInInv : hasInInv;
							
							if (isSatisfied) {
									manager.currentIndex++;
								} else {
								if (cmd.requested == null) {
									cmd.requested = true;
									if (("toggleBank" in world) && world.toggleBank != null) {
										world.toggleBank();
									}
									if (com.aqwapi.AqwApi.game != null) {
										}
								}
								manager.statusText = "MANUAL ACTION: Please " + (actionIsBank ? "BANK" : "UNBANK") + " " + cmd.args[0];
								manager.waitTimer = now + 1000;
							}
						} else {
							manager.currentIndex++;
						}
						return;
						
		}


	}
}
