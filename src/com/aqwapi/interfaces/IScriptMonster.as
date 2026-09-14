package com.aqwapi.interfaces {
    import com.aqwapi.data.EntityDTO;

    public interface IScriptMonster {
        function findByName(name:String, aliveOnly:Boolean = true):EntityDTO;
        function findByMapId(mapId:String, aliveOnly:Boolean = true):EntityDTO;
        function getLivingCells(name:String):Array;
        function getByCell(cell:String):Array;
    }
}
