package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptDrops;

    public class ScriptDrops implements IScriptDrops {
        private var _game:*;
        private var _pendingDrops:Array = [];
        private var _targetDrops:Array = [];
        private var _interceptedDropIds:Array = [];
        private var _rejectAll:Boolean = false;
        private var _acceptAll:Boolean = false;
        private var _acceptACs:Boolean = false;
        private var _isListening:Boolean = false;

        public function ScriptDrops(gameReference:*) {
            _game = gameReference;
        }

        public function get pendingDrops():Array { return _pendingDrops; }
        public function get targetDrops():Array { return _targetDrops; }
        public function set targetDrops(val:Array):void { _targetDrops = val; }
        public function get rejectAll():Boolean { return _rejectAll; }
        public function set rejectAll(val:Boolean):void { _rejectAll = val; }
        public function get acceptAll():Boolean { return _acceptAll; }
        public function get acceptACs():Boolean { return _acceptACs; }
        public function set acceptACs(value:Boolean):void { _acceptACs = value; }
        public function set acceptAll(val:Boolean):void { _acceptAll = val; }

        public function start():void {
            if (_isListening || !_game || !_game.sfc) return;
            _game.sfc.addEventListener("onExtensionResponse", onExtensionResponseHandler, false, int.MAX_VALUE, true);
            _isListening = true;
        }

        public function stop():void {
            if (!_isListening || !_game || !_game.sfc) return;
            _game.sfc.removeEventListener("onExtensionResponse", onExtensionResponseHandler);
            _isListening = false;
        }

        private function onExtensionResponseHandler(event:*):void {
            try {
                if (event.params.type == "json") {
                    var cmd:String = event.params.dataObj.cmd;
                    
                    if (cmd == "dropItem") {
                        var allIntercepted:Boolean = true;
                        var hasDrops:Boolean = false;
                        
                        for (var k:String in event.params.dataObj) {
                            if (k == "cmd") continue;
                            var val:* = event.params.dataObj[k];
                            if (val != null && typeof(val) == "object") {
                                for (var subK:String in val) {
                                    hasDrops = true;
                                    var item:* = val[subK];
                                    
                                    var matchesTarget:Boolean = isTargetDrop(item);
                                    var isAC:Boolean = (item.bCoins == 1 || item.bCoins == "1" || item.bCoins == true);
                                    
                                    if (_acceptAll || matchesTarget || (_acceptACs && isAC)) {
                                        if (_game.world != null && _game.sfc != null) {
                                            var roomId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
                                            _game.sfc.sendString("%xt%zm%getDrop%" + roomId + "%" + item.ItemID + "%");
                                        }
                                        if (item.ItemID != null) {
                                            _interceptedDropIds.push(String(item.ItemID));
                                        }
                                        delete val[subK];
                                    } else {
                                        allIntercepted = false;
                                        if (!_rejectAll) {
                                            addPendingDrop({
                                                sName: item.sName,
                                                ItemID: item.ItemID
                                            });
                                        } else {
                                            delete val[subK]; // Reject completely
                                        }
                                    }
                                }
                            }
                        }
                        
                        if (hasDrops && allIntercepted && event.hasOwnProperty("stopImmediatePropagation")) {
                            event.stopImmediatePropagation();
                        }
                    } 
                    else if (cmd == "getDrop") {
                        if (event.params.dataObj.ItemID != null) {
                            var resId:String = String(event.params.dataObj.ItemID);
                            var idx:int = _interceptedDropIds.indexOf(resId);
                            if (idx != -1) {
                                if (event.hasOwnProperty("stopImmediatePropagation")) {
                                    event.stopImmediatePropagation();
                                }
                                _interceptedDropIds.splice(idx, 1);
                            }
                        }
                    }
                }
            } catch (e:Error) {
                if (_game && _game.chatF != null) {
                }
            }
        }

        public function addPendingDrop(item:Object):void {
            if (item == null) return;

            var itemId:String = item.ItemID != null ? String(item.ItemID) : null;
            var itemName:String = item.sName != null ? String(item.sName).toLowerCase() : null;
            for each (var pending:Object in _pendingDrops) {
                if (pending == null) continue;
                if (itemId != null && pending.ItemID != null && String(pending.ItemID) == itemId) return;
                if (itemId == null && pending.ItemID == null && itemName != null && pending.sName != null && String(pending.sName).toLowerCase() == itemName) return;
            }

            _pendingDrops.push(item);
            if (_pendingDrops.length > 50) {
                _pendingDrops.shift();
            }
        }

        public function removePendingDrop(index:int):void {
            _pendingDrops.splice(index, 1);
        }

        public function acceptPendingDrops(itemNames:Array):int {
            if (!_game || !_game.sfc || itemNames == null || itemNames.length == 0) return 0;

            var accepted:int = 0;
            for (var i:int = _pendingDrops.length - 1; i >= 0; i--) {
                var pending:Object = _pendingDrops[i];
                if (pending == null || pending.sName == null) continue;

                var pendingName:String = String(pending.sName).toLowerCase();
				var pendingId:int = parseInt(pending.ItemID);
                var matches:Boolean = false;
				
				// Exact match or ID match first
                for each (var itemName:String in itemNames) {
					var inId:int = parseInt(itemName);
                    var inLower:String = itemName.toLowerCase();
					var isIdLookup:Boolean = !isNaN(inId) && inId > 0;
					
					if (inLower == "any" || inLower == "all") {
						matches = true; break;
					}
					
					if (isIdLookup) {
						if (pendingId == inId) { matches = true; break; }
					} else {
						if (pendingName == inLower) { matches = true; break; }
					}
                }
				
				// Fallback to indexOf if no exact match
				if (!matches) {
					for each (var itemName2:String in itemNames) {
						var inId2:int = parseInt(itemName2);
						var inLower2:String = itemName2.toLowerCase();
						var isIdLookup2:Boolean = !isNaN(inId2) && inId2 > 0;
						if (!isIdLookup2 && pendingName.indexOf(inLower2) != -1) {
							matches = true; break;
						}
					}
				}

                if (!matches) continue;

                var roomId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
                _game.sfc.sendString("%xt%zm%getDrop%" + roomId + "%" + pending.ItemID + "%");
                _pendingDrops.splice(i, 1);
                accepted++;
            }
            return accepted;
        }

        public function isTargetDrop(item:Object):Boolean {
            if (_targetDrops == null || _targetDrops.length == 0 || item == null || item.sName == null) return false;
            var searchName:String = String(item.sName).toLowerCase();
			var searchId:int = parseInt(item.ItemID);
			
			// Exact match or ID match first
            for each (var td:String in _targetDrops) {
                var tdLower:String = td.toLowerCase();
				var tdId:int = parseInt(td);
				var isIdLookup:Boolean = !isNaN(tdId) && tdId > 0;
				
                if (tdLower == "any" || tdLower == "all") return true;
				
				if (isIdLookup) {
					if (searchId == tdId) return true;
				} else {
					if (searchName == tdLower) return true;
				}
            }
			
			// Fallback to indexOf
			for each (var td2:String in _targetDrops) {
                var tdLower2:String = td2.toLowerCase();
				var tdId2:int = parseInt(td2);
				var isIdLookup2:Boolean = !isNaN(tdId2) && tdId2 > 0;
				if (!isIdLookup2 && searchName.indexOf(tdLower2) != -1) return true;
			}
			
            return false;
        }
    }
}
