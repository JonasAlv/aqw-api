package com.aqwapi.interfaces {
    public interface IScriptQuest {
		function load(questId:int):void;
        function isInProgress(questId:int):Boolean;
        function accept(questId:int):void;
        function complete(questId:int, itemId:int = -1):void;
        function isCompleted(questId:int):Boolean;
        
        function startAuto(questString:String):void;
        function stopAuto():void;
        function get isAutoRunning():Boolean;
    }
}
