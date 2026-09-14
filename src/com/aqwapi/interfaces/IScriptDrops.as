package com.aqwapi.interfaces {
    public interface IScriptDrops {
        function get pendingDrops():Array;
        function get targetDrops():Array;
        function set targetDrops(val:Array):void;
        function get rejectAll():Boolean;
        function set rejectAll(val:Boolean):void;
        function get acceptAll():Boolean;
        function get acceptACs():Boolean;
        function set acceptACs(val:Boolean):void;
        function set acceptAll(val:Boolean):void;
        
        function start():void;
        function stop():void;
        
        function addPendingDrop(item:Object):void;
        function removePendingDrop(index:int):void;
        function acceptPendingDrops(itemNames:Array):int;
        function isTargetDrop(itemName:String):Boolean;
    }
}
