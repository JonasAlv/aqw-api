package com.aqwapi.managers {
    import com.aqwapi.data.EntityDTO;
    import com.aqwapi.interfaces.IScriptMonster;

    public class ScriptMonster implements IScriptMonster {
        private var _game:*;

        public function ScriptMonster(gameReference:*) {
            _game = gameReference;
        }

        public function findByName(name:String, aliveOnly:Boolean = true):EntityDTO {
            var search:String = name != null ? name.toLowerCase() : "";
            for each (var monster:* in getRawMonsters()) {
                var target:EntityDTO = new EntityDTO(monster);
                if (target.name == null) continue;
                if ((search == "*" || target.name.toLowerCase().indexOf(search) != -1) && (!aliveOnly || target.alive)) {
                    return target;
                }
            }
            return null;
        }

        public function findByMapId(mapId:String, aliveOnly:Boolean = true):EntityDTO {
            if (mapId == null) return null;
            var search:String = String(mapId);
            for each (var monster:* in getRawMonsters()) {
                var target:EntityDTO = new EntityDTO(monster);
                if (target.mapId == search && (!aliveOnly || target.alive)) return target;
            }
            return null;
        }

        public function getLivingCells(name:String):Array {
            var cells:Array = [];
            var search:String = name != null ? name.toLowerCase() : "";
            for each (var monster:* in getRawMonsters()) {
                var target:EntityDTO = new EntityDTO(monster);
                if (!target.alive || target.cell == null) continue;
                if (search != "*" && target.name.toLowerCase().indexOf(search) == -1) continue;
                if (cells.indexOf(target.cell) == -1) cells.push(target.cell);
            }
            return cells;
        }

        public function getByCell(cell:String):Array {
            var result:Array = [];
            for each (var monster:* in getRawMonsters()) {
                var target:EntityDTO = new EntityDTO(monster);
                if (target.cell == cell) result.push(target);
            }
            return result;
        }

        private function getRawMonsters():* {
            if (!_game || !_game.world || _game.world.monsters == null) return [];
            return _game.world.monsters;
        }
    }
}
