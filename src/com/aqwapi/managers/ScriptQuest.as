package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptQuest;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.aqwapi.events.ApiEvent;
	import com.aqwapi.AqwApi;

    public class ScriptQuest implements IScriptQuest {
        private var _game:*;
        private var _timer:Timer;
        private var _questIDs:Array = [];
        private var _lastTurnIns:Object = {};

        public function ScriptQuest(gameReference:*) {
            _game = gameReference;
        }

		public function load(questId:int):void {
			if (_game != null && _game.world != null && _game.world.getQuests != null) {
				_game.world.getQuests([questId]);
			}
		}

		public function isInProgress(questId:int):Boolean {
			if (_game && _game.world && _game.world.isQuestInProgress != null) {
				return _game.world.isQuestInProgress(questId);
			}
			return false;
		}

		public function accept(questId:int):void {
            if (_game && _game.world && _game.world.acceptQuest != null) {
                if (_game.world.questTree != null && _game.world.questTree[questId] != null) {
                    _game.world.acceptQuest(questId);
                } else {
                    AqwApi.dispatcher.dispatchEvent(new ApiEvent(
                        ApiEvent.NOTIFICATION,
                        "Quest " + questId + " not loaded! Skipping accept."
                    ));
                }
            }
        }

        public function complete(questId:int, itemId:int = -1):void {
            if (_game && _game.world && _game.world.tryQuestComplete != null) {
                if (itemId > 0) {
                    _game.world.tryQuestComplete(questId, itemId);
                } else {
                    _game.world.tryQuestComplete(questId);
                }
            }
        }

        public function isCompleted(questId:int):Boolean {
            if (!_game || !_game.world || !_game.world.questTree) return false;
            
            var qTree:Object = _game.world.questTree;
            var qData:Object = qTree[questId];
            
            if (qData == null) return false;

            var qslot:int = (qData.iSlot != null) ? int(qData.iSlot) : -1;
            var qval:int = (qData.iValue != null) ? int(qData.iValue) : 0;
            
            if (qslot >= 0) {
                try {
                    if (_game.world.getQuestValue != null) {
                        var slotVal:* = _game.world.getQuestValue(qslot);
                        if (slotVal != null && int(slotVal) >= qval) {
                            return true;
                        }
                    }
                } catch(e:Error) {}
                
                try {
                    if (_game.world.questSlots != null && _game.world.questSlots[qslot] != null) {
                        if (int(_game.world.questSlots[qslot]) >= qval) {
                            return true;
                        }
                    }
                } catch(e:Error) {}
            }
            
            return false;
        }

        public function get isAutoRunning():Boolean {
            return _timer != null && _timer.running;
        }

        public function startAuto(questString:String):void {
            stopAuto();
            
            if (questString == null || questString.length == 0) return;
            
            var parts:Array = questString.split(",");
            _questIDs = [];
            for (var i:int = 0; i < parts.length; i++) {
                var raw:String = parts[i];
                var subParts:Array = raw.split(":");
                var val:int = parseInt(subParts[0]);
                if (!isNaN(val) && val > 0) {
                    var itemId:int = -1;
                    if (subParts.length > 1) {
                        itemId = parseInt(subParts[1]);
                    }
                    _questIDs.push({qid: val, itemId: itemId});
                }
            }

            if (_questIDs.length > 0) {
                _lastTurnIns = {};
                _timer = new Timer(1500);
                _timer.addEventListener(TimerEvent.TIMER, onAutoTick, false, 0, true);
                _timer.start();
            }
        }

        public function stopAuto():void {
            if (_timer != null) {
                _timer.stop();
                _timer.removeEventListener(TimerEvent.TIMER, onAutoTick);
                _timer = null;
            }
        }

        private function onAutoTick(e:TimerEvent):void {
            if (!_game || !_game.world) return;
            
            try {
                if (_game.world.questTree != null) {
                    var now:Number = new Date().getTime();
                    for (var i:int = 0; i < _questIDs.length; i++) {
                        var qObj:Object = _questIDs[i];
                        var qid:int = qObj.qid;
                        var itemId:int = qObj.itemId;
                        
                        var lastAttempt:Number = 0;
                        if (_lastTurnIns[qid] != null) {
                            lastAttempt = _lastTurnIns[qid];
                        }
                        
                        if (now - lastAttempt < 2000) {
                            continue;
                        }

                        var quest:* = _game.world.questTree[qid];
                        if (quest != null) {
                            if (quest.status == "c") {
                                _lastTurnIns[qid] = now;
                                complete(qid, itemId);
                                break;
                            } else if (quest.status == null || quest.status == "") {
                                _lastTurnIns[qid] = now;
                                accept(qid);
                                break;
                            }
                        } else {
                            _lastTurnIns[qid] = now;
                            accept(qid);
                            break;
                        }
                    }
                }
            } catch (err:Error) {
                trace("AutoQuest Error: " + err.message);
            }
        }
    }
}
