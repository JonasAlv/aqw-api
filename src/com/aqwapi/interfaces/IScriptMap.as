package com.aqwapi.interfaces {
    public interface IScriptMap {
        function join(mapName:String, cell:String = "Enter", pad:String = "Spawn"):void;
        function jump(cell:String, pad:String = "Enter"):void;
        function getMapItem(itemId:int):Boolean;
        function snapTo(target:*):void;
        function get isLoaded():Boolean;
        function get name():String;
    }
}
