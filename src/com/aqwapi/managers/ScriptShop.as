package com.aqwapi.managers {
	import com.aqwapi.interfaces.IScriptShop;

	public class ScriptShop implements IScriptShop {
		private var _game:*;

		public function ScriptShop(gameReference:*) {
			_game = gameReference;
		}

		public function loadShop(shopId:int):void {
			if (_game == null || _game.world == null) return;
			if (isNaN(shopId) || shopId <= 0) return;
			try {
				if (isShopLoaded && loadedShopId == shopId) return;
				if ("sendLoadShopRequest" in _game.world) {
					_game.world.sendLoadShopRequest(shopId);
				}
			} catch(e:Error) {}
		}

public function buyItem(itemNameOrId:String, quantity:int = 1):void {
		if (quantity < 1) quantity = 1;
		if (_game == null || _game.world == null || _game.ui == null || _game.ui.mcPopup == null || _game.ui.mcPopup.currentLabel != "Shop") return;

		var targetId:int = parseInt(itemNameOrId);
		var isIdLookup:Boolean = !isNaN(targetId) && targetId > 0;
		var target:String = itemNameOrId.toLowerCase();
		try {
			var shopInfo:* = null;
			if (_game.world.shopinfo != null) shopInfo = _game.world.shopinfo;
			else {
				var mcShop:* = _game.ui.mcPopup.getChildByName("mcShop");
				if (mcShop != null) shopInfo = mcShop.shopinfo;
			}
			if (shopInfo != null && shopInfo.items != null) {
				var sItems:Array = shopInfo.items;
				for (var si:int = 0; si < sItems.length; si++) {
					if (sItems[si] == null || sItems[si].sName == null) continue;
					var matches:Boolean = isIdLookup ? (sItems[si].ItemID == targetId) : (String(sItems[si].sName).toLowerCase() == target);
					if (matches) {
						// Check if we already own a non-stackable item (iStk == 1 means max 1 owned)
						if (sItems[si].iStk != null && int(sItems[si].iStk) <= 1) {
							// Already own this item, skip buying
							if (_game.world.myAvatar != null && _game.world.myAvatar.items != null) {
								var myItems:Array = _game.world.myAvatar.items;
								for (var mi:int = 0; mi < myItems.length; mi++) {
									if (myItems[mi] != null && myItems[mi].ItemID != null && myItems[mi].ItemID == sItems[si].ItemID) {
										return;
									}
								}
							}
						}
						if (quantity > 1 && "sendBuyItemRequestWithQuantity" in _game.world) {
							var buyObj:* = new Object();
							buyObj.iSel = sItems[si];
							buyObj.iQty = quantity;
							buyObj.accept = 1;
							_game.world.sendBuyItemRequestWithQuantity(buyObj);
						} else if ("sendBuyItemRequest" in _game.world) {
							_game.world.sendBuyItemRequest(sItems[si]);
						}
						break;
					}
				}
			}
		} catch(e:Error) {}
	}

public function sellItem(itemNameOrId:String, quantity:int = 1):void {
		if (quantity < 1) quantity = 1;
		if (_game == null || _game.world == null) return;

		var targetId:int = parseInt(itemNameOrId);
		var isIdLookup:Boolean = !isNaN(targetId) && targetId > 0;
		var target:String = itemNameOrId.toLowerCase();
		try {
			if (_game.world.myAvatar != null && _game.world.myAvatar.items != null) {
				var myItems:Array = _game.world.myAvatar.items;
				for (var i:int = 0; i < myItems.length; i++) {
					if (myItems[i] == null || myItems[i].sName == null) {
						trace("sellItem: skipping null item at index " + i);
						continue;
					}
					var matches:Boolean = isIdLookup ? (myItems[i].ItemID == targetId) : (String(myItems[i].sName).toLowerCase() == target);
					if (matches) {
						// Skip equipped items (can't sell equipped items)
						if (myItems[i].bEquip == true) {
							trace("sellItem: item is equipped, cannot sell: " + myItems[i].sName);
							continue;
						}
						// Need CharItemID to sell
						if (myItems[i].CharItemID == null || myItems[i].CharItemID == 0) {
							trace("sellItem: missing CharItemID for: " + myItems[i].sName);
							continue;
						}
						trace("sellItem: selling " + myItems[i].sName + " CharItemID=" + myItems[i].CharItemID + " ItemID=" + myItems[i].ItemID + " qty=" + quantity);
						if (_game.sfc != null) {
							var reqId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.world.curRoom;
							_game.sfc.sendString("%xt%zm%sellItem%" + reqId + "%" + myItems[i].ItemID + "%" + quantity + "%" + myItems[i].CharItemID + "%");
						} else if ("sendSellItemRequest" in _game.world) {
							_game.world.sendSellItemRequest(myItems[i]);
						}
						break;
					}
				}
			}
		} catch(e:Error) {
			trace("sellItem: error: " + e.message);
		}
	}

		public function get isShopLoaded():Boolean {
			if (_game == null || _game.ui == null || _game.ui.mcPopup == null) return false;
			return _game.ui.mcPopup.currentLabel == "Shop";
		}

		public function get loadedShopId():int {
			try {
				if (_game != null && _game.world != null && _game.world.shopinfo != null && _game.world.shopinfo.ShopID != null) {
					return int(_game.world.shopinfo.ShopID);
				}
				if (_game != null && _game.ui != null && _game.ui.mcPopup != null && _game.ui.mcPopup.currentLabel == "Shop") {
					var mcShop:* = _game.ui.mcPopup.getChildByName("mcShop");
					if (mcShop != null && mcShop.shopinfo != null && mcShop.shopinfo.ShopID != null) {
						return int(mcShop.shopinfo.ShopID);
					}
				}
			} catch(e:Error) {}
			return 0;
		}
	}
}