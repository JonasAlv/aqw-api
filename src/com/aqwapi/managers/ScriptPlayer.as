package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptPlayer;

    public class ScriptPlayer implements IScriptPlayer {
        private var _game:*;

        public function ScriptPlayer(gameReference:*) {
            _game = gameReference;
        }

        public function moveToCell(cell:String, pad:String):void {
            if (_game && _game.world && _game.world.moveToCell != null) {
                _game.world.moveToCell(cell, pad);
            }
        }

        public function jump(x:Number, y:Number):void {
            if (_game && _game.world && _game.world.myAvatar != null && _game.world.myAvatar.pMC != null) {
                _game.world.myAvatar.pMC.x = x;
                _game.world.myAvatar.pMC.y = y;
            }
        }

        public function get state():int {
            if (_game && _game.world && _game.world.myAvatar != null) {
                return _game.world.myAvatar.state;
            }
            return 0; // 0 = Dead/Unloaded, 1 = Idle, 2 = Combat
        }
    }
}
