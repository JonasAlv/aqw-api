package com.aqwapi.managers {
    import com.aqwapi.interfaces.IScriptCombat;
    import com.aqwapi.modules.CombatManager;
    import flash.display.DisplayObject;

    public class ScriptCombat implements IScriptCombat {
        private var _game:*;

        public function ScriptCombat(gameReference:*) {
            _game = gameReference;
        }

        public function attack(monsterName:String):void {
            if (!_game || !_game.world || !_game.world.myAvatar || !_game.world.getMonster) return;
            
            var targetName:String = monsterName.toLowerCase();
            var targetMonster:Object = null;
            
            if (targetName == "*") {
                targetMonster = _game.world.getMonster("Any");
            } else {
                targetMonster = _game.world.getMonster(targetName);
            }
            
            if (targetMonster != null) {
                if (_game.world.setTarget != null) {
                    _game.world.setTarget(targetMonster);
                }
                if (_game.world.approachTarget != null) {
                    _game.world.approachTarget();
                }
            }
        }

        public function dropCombat():void {
            if (!_game || !_game.world || !_game.world.myAvatar || !("moveToCell" in _game.world)) return;
            
            var currentCell:String = _game.world.strFrame;
            var currentPad:String = _game.world.strPad;
            _game.world.moveToCell(currentCell, currentPad);
        }

        public function startSmart():void {
            CombatManager.start(true, false);
        }

        public function startCustom(rotation:String):void {
            if (rotation && rotation.length > 0) {
                var rotInts:Array = [];
                // If it contains commas, e.g. "1,2,3,4"
                if (rotation.indexOf(",") != -1) {
                    var rotParts:Array = rotation.split(",");
                    for each (var rp:String in rotParts) { 
                        var ri:int = parseInt(rp); 
                        if (!isNaN(ri) && ri > 0) rotInts.push(ri); 
                    }
                } else {
                    // It's a continuous string like "222534"
                    for (var i:int = 0; i < rotation.length; i++) {
                        var charVal:int = parseInt(rotation.charAt(i));
                        if (!isNaN(charVal) && charVal > 0) rotInts.push(charVal);
                    }
                }
                if (rotInts.length > 0) {
                    CombatManager.setCustomRotation(rotInts);
                }
            }
            CombatManager.start(false, false);
        }

        public function stopAuto():void {
            CombatManager.stop();
            dropCombat();
        }

        public function get isAutoRunning():Boolean {
            return CombatManager.IS_ON;
        }

        public function get mode():String {
            return CombatManager.skillMode;
        }

        public function set mode(value:String):void {
            CombatManager.skillMode = value;
        }
    }
}
