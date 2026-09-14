package com.aqwapi.data {
    public class QuestDTO {
        public var questId:int;
        public var name:String;
        public var status:String;
        public var requirements:Array;
        public var rewards:Array;

        public function QuestDTO(rawData:*) {
            if (!rawData) return;
            this.questId = rawData.QuestID != null ? parseInt(rawData.QuestID) : 0;
            this.name = rawData.sName != null ? String(rawData.sName) : "";
            this.status = rawData.status != null ? String(rawData.status) : "";
        }
    }
}
