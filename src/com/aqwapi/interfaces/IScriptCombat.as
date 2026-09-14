package com.aqwapi.interfaces {
    public interface IScriptCombat {
        function attack(monsterName:String):void;
        function dropCombat():void;
        
        function startSmart():void;
        function startCustom(rotation:String):void;
        function stopAuto():void;
        function get isAutoRunning():Boolean;
    }
}
