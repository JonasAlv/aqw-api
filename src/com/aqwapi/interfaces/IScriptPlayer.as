package com.aqwapi.interfaces {
    public interface IScriptPlayer {
        function moveToCell(cell:String, pad:String):void;
        function jump(x:Number, y:Number):void;
        function get state():int;
    }
}
