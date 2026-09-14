package com.aqwapi.interfaces {
	public interface IScriptShop {
		function loadShop(shopId:int):void;
		function buyItem(itemName:String, quantity:int = 1):void;
		function sellItem(itemName:String, quantity:int = 1):void;
		function get isShopLoaded():Boolean;
		function get loadedShopId():int;
	}
}
