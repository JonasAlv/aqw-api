package com.aqwapi.interfaces {
    public interface IScriptCombat {
        function attack(monsterName:String):void;
        function dropCombat():void;
        
        function startSmart():void;
        function startCustom(rotation:String):void;
        function stopAuto():void;
        function get isAutoRunning():Boolean;
        
        function get mode():String;
        function set mode(value:String):void;
        
        function get farmClass():String;
        function set farmClass(value:String):void;
        function get farmMode():String;
        function set farmMode(value:String):void;
        
        function get soloClass():String;
        function set soloClass(value:String):void;
        function get soloMode():String;
        function set soloMode(value:String):void;
        
        function equipLoadout(type:String):Boolean;
    }
}
