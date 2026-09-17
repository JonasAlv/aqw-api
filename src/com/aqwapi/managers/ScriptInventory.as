package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptInventory;

    public class ScriptInventory implements IScriptInventory {
        private var _game:*;

        public function ScriptInventory(gameReference:*) {
            _game = gameReference;
        }

        public function hasItem(itemName:String, quantity:int = 1):Boolean {
            return getQuantity(itemName) >= quantity;
        }

        public function getQuantity(itemNameOrId:String):int {
            if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.myAvatar.items) {
                return 0;
            }
            
            var targetId:int = parseInt(itemNameOrId);
            var isIdLookup:Boolean = !isNaN(targetId) && targetId > 0;
            var targetName:String = itemNameOrId.toLowerCase();
			
            for each (var item:Object in _game.world.myAvatar.items) {
                if (item.sName != null) {
                    var matches:Boolean = isIdLookup ? (item.ItemID == targetId) : (String(item.sName).toLowerCase() == targetName);
                    if (matches) {
                        return (item.iQty != null) ? int(item.iQty) : 1;
                    }
                }
            }
            return 0;
        }

        public function getQuestQuantity(itemName:String):int {
            if (!_game || !_game.world) return 0;

            var targetNames:Array = itemName.toLowerCase().split("|");
            var countedNames:Object = {};
            var quantity:int = 0;

            if (_game.world.invTree != null) {
                for (var key:String in _game.world.invTree) {
                    var item:* = _game.world.invTree[key];
                    quantity += addQuestQuantity(item, targetNames, countedNames);
                }
            }

            if (_game.world.myAvatar != null && _game.world.myAvatar.tempitems != null) {
                for each (var avatarItem:* in _game.world.myAvatar.tempitems) {
                    quantity += addQuestQuantity(avatarItem, targetNames, countedNames);
                }
            }

            return quantity;
        }

        private function addQuestQuantity(item:*, targetNames:Array, countedNames:Object):int {
            if (item == null || item.sName == null) return 0;

            var itemName:String = String(item.sName).toLowerCase();
            for each (var targetName:String in targetNames) {
				var targetId:int = parseInt(targetName);
				var isIdLookup:Boolean = !isNaN(targetId) && targetId > 0;
				var matches:Boolean = isIdLookup ? (item.ItemID == targetId) : (itemName == targetName);
				
                if (matches) {
                    if (countedNames[targetName]) return 0;
                    countedNames[targetName] = true;
                    var value:Number = parseFloat(item.iQty);
                    return isNaN(value) ? 1 : int(value);
                }
            }
            return 0;
        }

public function equip(itemNameOrId:String):void {
			if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.myAvatar.items) return;
            var itemId:int = parseInt(itemNameOrId);
            var isIdLookup:Boolean = !isNaN(itemId) && itemId > 0;
            var targetName:String = itemNameOrId.toLowerCase();
			var bestMatch:Object = null;
            for each (var item:Object in _game.world.myAvatar.items) {
                if (item == null || item.sName == null) continue;
				if (isIdLookup) {
					if (item.ItemID == itemId) { bestMatch = item; break; }
				} else {
					var sNameL:String = String(item.sName).toLowerCase();
					if (sNameL == targetName) {
						bestMatch = item;
						break;
					} else if (sNameL.indexOf(targetName) != -1 && bestMatch == null) {
						bestMatch = item;
					}
				}
            }
			if (bestMatch != null) {
				if (bestMatch.bEquip == 1 || bestMatch.bEquip == "1" || bestMatch.bEquip == true) return;
				if ("sendEquipItemRequest" in _game.world) {
					_game.world.sendEquipItemRequest(bestMatch);
				} else if (_game.sfc != null) {
					var reqId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.world.curRoom;
					_game.sfc.sendString("%xt%zm%equipItem%" + reqId + "%" + bestMatch.ItemID + "%");
				}
			}
        }

        public function isEquipped(itemNameOrId:String):Boolean {
            if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.myAvatar.items) return false;
            var itemId:int = parseInt(itemNameOrId);
            var isIdLookup:Boolean = !isNaN(itemId) && itemId > 0;
            var targetName:String = itemNameOrId.toLowerCase();
            for each (var item:Object in _game.world.myAvatar.items) {
                if (item == null || item.sName == null) continue;
                var matches:Boolean = isIdLookup ? (item.ItemID == itemId) : (String(item.sName).toLowerCase() == targetName);
                if (matches) {
                    return item.bEquip == 1 || item.bEquip == "1" || item.bEquip == true;
                }
            }
            return false;
        }

        public function equipUsable(itemNameOrId:String):void {
            if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.myAvatar.items) return;
            var itemId:int = parseInt(itemNameOrId);
            var isIdLookup:Boolean = !isNaN(itemId) && itemId > 0;
            var targetName:String = itemNameOrId.toLowerCase();
            for each (var item:Object in _game.world.myAvatar.items) {
                if (item == null || item.sName == null) continue;
                var matches:Boolean = isIdLookup ? (item.ItemID == itemId) : (String(item.sName).toLowerCase() == targetName);
                if (matches) {
                    if ("equipUseableItem" in _game.world) {
                        var usableObj:* = {};
                        usableObj.ItemID = item.ItemID;
                        usableObj.sName = item.sName;
                        usableObj.sDesc = item.sDesc;
                        usableObj.sFile = item.sFile;
                        _game.world.equipUseableItem(usableObj);
                    }
                    return;
                }
            }
        }

        public function bank(itemName:String):void {
            if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.myAvatar.items) return;
            var targetName:String = itemName.toLowerCase();
            for each (var bItem:Object in _game.world.myAvatar.items) {
                if (bItem.sName != null && String(bItem.sName).toLowerCase() == targetName) {
                    if (_game.world.sendBankFromInvRequest != null) {
                        _game.world.sendBankFromInvRequest(bItem);
                    } else if (_game.sfc != null) {
                        var reqId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
                        _game.sfc.sendString("%xt%zm%bankFromInv%" + reqId + "%" + bItem.ItemID + "%" + bItem.CharItemID + "%");
                    }
                    return;
                }
            }
        }

        public function unbank(itemName:String):void {
            if (!_game || !_game.world || !_game.world.bankinfo || !_game.world.bankinfo.items) return;
            var targetName:String = itemName.toLowerCase();
            for each (var uItem:Object in _game.world.bankinfo.items) {
                if (uItem.sName != null && String(uItem.sName).toLowerCase() == targetName) {
                    if (_game.world.sendBankToInvRequest != null) {
                        _game.world.sendBankToInvRequest(uItem);
                    } else if (_game.sfc != null) {
                        var reqId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
                        _game.sfc.sendString("%xt%zm%bankToInv%" + reqId + "%" + uItem.ItemID + "%" + uItem.CharItemID + "%");
                    }
                    return;
                }
            }
        }

        public function loadBank():void {
            if (!_game || !_game.world || !_game.sfc) return;
            var reqId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
            _game.sfc.sendString("%xt%zm%loadBank%" + reqId + "%");
        }

        public function toggleBank():void {
            if (_game && _game.world && "toggleBank" in _game.world) {
                _game.world.toggleBank();
            }
        }
    }
}
