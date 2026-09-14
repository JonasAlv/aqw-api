package com.aqwapi.interfaces {
    public interface IScriptInventory {
        function hasItem(itemName:String, quantity:int = 1):Boolean;
        function getQuantity(itemName:String):int;
        function getQuestQuantity(itemName:String):int;
        function equip(itemNameOrId:String):void;
        function equipUsable(itemNameOrId:String):void;
        function bank(itemName:String):void;
        function unbank(itemName:String):void;
        function loadBank():void;
        function toggleBank():void;
    }
}
