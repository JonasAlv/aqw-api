package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptMap;
    import com.aqwapi.AqwApi;

    public class ScriptMap implements IScriptMap {
        private var _game:*;

        public function ScriptMap(gameReference:*) {
            _game = gameReference;
        }

        public function jump(cell:String, pad:String = "Enter"):void {
            if (_game && _game.world && "moveToCell" in _game.world) {
                if (_game.world.strFrame != cell) {
                    _game.world.moveToCell(cell, pad);
                }
            }
        }

        public function join(mapName:String, roomNumber:String = "Enter", cell:String = "Spawn"):void {
            if (_game && _game.world && _game.sfc != null && _game.world.myAvatar != null) {
                var username:String = _game.world.myAvatar.objData.strUsername;
                if (mapName.indexOf("-") == -1 && roomNumber == "100000") {
                    mapName += "-100000";
                }
                if (mapName.indexOf("-") != -1) {
                    AqwApi.transport.send("zm", "cmd", ["1", "tfer", username, mapName]);
                } else {
                    _game.world.gotoTown(mapName, roomNumber, cell);
                }
            }
        }

        public function getMapItem(itemId:int):Boolean {
            if (!_game || !_game.sfc) return false;
            AqwApi.transport.sendExtensionCommand("getMapItem", [itemId]);
            return true;
        }

        public function snapTo(target:*):void {
            if (target != null && target.pMC != null && _game.world != null && _game.world.myAvatar != null && _game.world.myAvatar.pMC != null) {
                _game.world.myAvatar.pMC.x = target.pMC.x;
                _game.world.myAvatar.pMC.y = target.pMC.y;
            }
        }

        public function get isLoaded():Boolean {
            if (_game && _game.world) {
                if (_game.world.mapLoadInProgress == false && _game.world.myAvatar != null && _game.world.myAvatar.pMC != null) {
                    return true;
                }
            }
            return false;
        }

        public function get name():String {
            if (_game && _game.world && _game.world.strMapName != null) {
                return _game.world.strMapName;
            }
            return "";
        }
    }
}
