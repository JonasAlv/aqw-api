package com.aqwapi.events {
    import flash.events.Event;

    public class ApiEvent extends Event {
        public static const NOTIFICATION:String = "apiNotification";
        public static const SCRIPT_STARTED:String = "apiScriptStarted";
        public static const SCRIPT_STOPPED:String = "apiScriptStopped";
        public static const COMBAT_TOGGLED:String = "apiCombatToggled";

        public var message:String;
        public var data:Object;

        public function ApiEvent(type:String, message:String = "", data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            this.message = message;
            this.data = data;
        }

        override public function clone():Event {
            return new ApiEvent(type, message, data, bubbles, cancelable);
        }
    }
}
