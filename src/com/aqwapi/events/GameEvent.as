package com.aqwapi.events {
    import flash.events.Event;

    public class GameEvent extends Event {
        public static const ZONE_ENTERED:String = "zoneEntered";
        public static const QUEST_UPDATED:String = "questUpdated";
        public static const INVENTORY_CHANGED:String = "inventoryChanged";
        
        public var data:Object;

        public function GameEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            this.data = data;
        }
        
        override public function clone():Event {
            return new GameEvent(type, data, bubbles, cancelable);
        }
    }
}
