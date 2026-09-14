package com.aqwapi.data {
    public class ItemDTO {
        public var itemId:int;
        public var name:String;
        public var type:String;
        public var quantity:int;
        
        public function ItemDTO(rawData:*) {
            if (!rawData) return;
            this.itemId = rawData.ItemID != null ? parseInt(rawData.ItemID) : 0;
            this.name = rawData.sName != null ? String(rawData.sName) : "";
            this.type = rawData.sType != null ? String(rawData.sType) : "";
            this.quantity = rawData.iQty != null ? parseInt(rawData.iQty) : 1;
        }
    }
}
