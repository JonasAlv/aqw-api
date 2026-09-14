package com.aqwapi.data {
    public class EntityDTO {
        public var id:String;
        public var name:String;
        public var cell:String;
        public var hp:int;
        public var mp:int;
        public var state:int;
        public var mapId:String;
        public var monsterId:String;
        public var raw:*;

        public function get alive():Boolean {
            return hp > 0 && state > 0;
        }

        public function EntityDTO(rawData:*) {
            if (!rawData) return;
            this.raw = rawData;
            
            // Name
            if (rawData.objData) {
                this.name = rawData.objData.strMonName || rawData.objData.strUsername || "";
            }
            if (!this.name && rawData.dataLeaf) {
                this.name = rawData.dataLeaf.strMonName || rawData.dataLeaf.strUsername || "";
            }
            if (!this.name) this.name = rawData.strMonName || rawData.strUsername || "";

            // HP
            if (rawData.dataLeaf != null && rawData.dataLeaf.intHP != null) this.hp = int(rawData.dataLeaf.intHP);
            else if (rawData.objData != null && rawData.objData.intHP != null) this.hp = int(rawData.objData.intHP);
            else if (rawData.intHP != null) this.hp = int(rawData.intHP);

            // MP
            if (rawData.dataLeaf != null && rawData.dataLeaf.intMP != null) this.mp = int(rawData.dataLeaf.intMP);
            else if (rawData.objData != null && rawData.objData.intMP != null) this.mp = int(rawData.objData.intMP);
            else if (rawData.intMP != null) this.mp = int(rawData.intMP);

            // State
            if (rawData.dataLeaf != null && rawData.dataLeaf.intState != null) this.state = int(rawData.dataLeaf.intState);
            else if (rawData.objData != null && rawData.objData.intState != null) this.state = int(rawData.objData.intState);
            else if (rawData.intState != null) this.state = int(rawData.intState);

            // Cell (strFrame)
            if (rawData.pMC != null && rawData.pMC.currentLabel != null && String(rawData.pMC.currentLabel) != "") {
                this.cell = String(rawData.pMC.currentLabel);
            } else if (rawData.dataLeaf != null && rawData.dataLeaf.strFrame != null && String(rawData.dataLeaf.strFrame) != "") {
                this.cell = String(rawData.dataLeaf.strFrame);
            } else if (rawData.objData != null && rawData.objData.strFrame != null && String(rawData.objData.strFrame) != "") {
                this.cell = String(rawData.objData.strFrame);
            } else if (rawData.strFrame != null && String(rawData.strFrame) != "") {
                this.cell = String(rawData.strFrame);
            } else {
                this.cell = "";
            }

            // IDs
            if (rawData.dataLeaf) {
                this.id = rawData.dataLeaf.MonMapID || rawData.dataLeaf.entID || "";
                this.mapId = rawData.dataLeaf.MonMapID || "";
                this.monsterId = rawData.dataLeaf.MonID || "";
            } else if (rawData.objData && rawData.objData.MonMapID) {
                this.id = rawData.objData.MonMapID;
            }
            
            if (!this.mapId && rawData.objData && rawData.objData.MonMapID) this.mapId = String(rawData.objData.MonMapID);
            if (!this.mapId && rawData.MonMapID) this.mapId = String(rawData.MonMapID);
            
            if (!this.monsterId && rawData.objData && rawData.objData.MonID) this.monsterId = String(rawData.objData.MonID);
            if (!this.monsterId && rawData.MonID) this.monsterId = String(rawData.MonID);
        }
    }
}
