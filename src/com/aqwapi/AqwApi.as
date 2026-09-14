package com.aqwapi {
    import com.aqwapi.interfaces.*;
    import com.aqwapi.managers.*;
    import com.aqwapi.net.TransportAdapter;
    import flash.events.EventDispatcher;

    public class AqwApi {
        
        // Expose a global event dispatcher for the API
        public static const dispatcher:EventDispatcher = new EventDispatcher();
        
        // The raw game object reference
        private static var _game:*;
        public static function get game():* { return _game; }
        
        // Skua-style interface exposures
        private static var _map:IScriptMap;
        private static var _player:IScriptPlayer;
        private static var _quest:IScriptQuest;
        private static var _combat:IScriptCombat;
        private static var _inventory:IScriptInventory;
        private static var _drops:IScriptDrops;
        private static var _shop:IScriptShop;
        private static var _monsters:IScriptMonster;
        private static var _transport:TransportAdapter;

        public static function get map():IScriptMap { return _map; }
        public static function get player():IScriptPlayer { return _player; }
        public static function get quest():IScriptQuest { return _quest; }
        public static function get combat():IScriptCombat { return _combat; }
        public static function get inventory():IScriptInventory { return _inventory; }
        public static function get drops():IScriptDrops { return _drops; }
        public static function get shop():IScriptShop { return _shop; }
        public static function get monsters():IScriptMonster { return _monsters; }
        public static function get transport():TransportAdapter { return _transport; }
        
        // Initialization
        public static function init(gameReference:*):void {
            _game = gameReference;
            
            _transport = new TransportAdapter(_game);

            // Instantiate the manager implementations that fulfill the interfaces
            _map = new ScriptMap(_game);
            _quest = new ScriptQuest(_game);
            _combat = new ScriptCombat(_game);
            _inventory = new ScriptInventory(_game);
            _player = new ScriptPlayer(_game);
            _drops = new ScriptDrops(_game);
            _shop = new ScriptShop(_game);
            _monsters = new ScriptMonster(_game);
        }
        
        // Helper to check if game is fully loaded
        public static function get isReady():Boolean {
            return (_game != null && _game.world != null);
        }
    }
}
