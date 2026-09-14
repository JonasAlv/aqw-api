package com.aqwapi.net {
    public class TransportAdapter {
        private var _game:*;

        public function TransportAdapter(gameReference:*) {
            _game = gameReference;
        }

        public function send(namespaceId:String, command:String, args:Array):void {
            if (!_game || !_game.sfc) return;

            var packet:String = "%xt%" + namespaceId + "%" + command + "%";
            packet += args.join("%") + "%";

            _game.sfc.sendString(packet);
            trace("[TransportAdapter] Sent: " + packet);
        }
        
        public function sendExtensionCommand(command:String, args:Array):void {
            if (!_game || !_game.sfc) return;
            var roomId:* = (_game.sfc.activeRoomId != null) ? _game.sfc.activeRoomId : _game.sfc.myUserId;
            var fullArgs:Array = [roomId].concat(args);
            send("zm", command, fullArgs);
        }

        // Hooked from the client (e.g. Network.as)
        public function handleResponse(event:*):void {
            if (event.params == null) return;
            
            var type:String = event.params.type;
            var cmd:String = "";
            var dataObj:Object = null;
            
            if (type == "json") {
                cmd = event.params.dataObj.cmd;
                dataObj = event.params.dataObj;
            } else if (type == "str") {
                var resObj:Array = event.params.dataObj;
                cmd = resObj[0];
                dataObj = resObj;
            } else if (type == "xml") {
                // Not fully mapped yet, but structure is generally available in dataObj
                if (event.params.dataObj != null) {
                    cmd = event.params.dataObj.name; // Can vary based on how ObjectSerializer parses it
                }
            }

            // Dispatch specific GameEvents based on the command
            import com.aqwapi.events.GameEvent;
            import com.aqwapi.AqwApi;
            
            switch (cmd) {
                case "moveToArea":
                    AqwApi.dispatcher.dispatchEvent(new GameEvent(GameEvent.ZONE_ENTERED, dataObj));
                    break;
                case "getQuests":
                case "getQuests2":
                case "getQuest":
                    AqwApi.dispatcher.dispatchEvent(new GameEvent(GameEvent.QUEST_UPDATED, dataObj));
                    break;
                case "equipItem":
                case "unequipItem":
                case "buyItem":
                case "sellItem":
                case "getDrop":
                    AqwApi.dispatcher.dispatchEvent(new GameEvent(GameEvent.INVENTORY_CHANGED, dataObj));
                    break;
            }
        }
    }
}
