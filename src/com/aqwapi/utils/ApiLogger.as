package com.aqwapi.utils {
    import com.aqwapi.AqwApi;

    public class ApiLogger {
        public static const LEVEL_DEBUG:int = 0;
        public static const LEVEL_INFO:int  = 1;
        public static const LEVEL_WARN:int  = 2;
        public static const LEVEL_ERROR:int = 3;
        public static const LEVEL_OFF:int   = 4;

        public static var level:int = LEVEL_INFO;
        public static var printToConsole:Boolean = true;
        public static var printToChat:Boolean = false;
        public static var chatMinLevel:int = LEVEL_WARN;
        public static var onLog:Function = null;

        public static function debug(tag:String, message:String):void {
            log(tag, LEVEL_DEBUG, message);
        }

        public static function info(tag:String, message:String):void {
            log(tag, LEVEL_INFO, message);
        }

        public static function warn(tag:String, message:String):void {
            log(tag, LEVEL_WARN, message);
        }

        public static function error(tag:String, message:String):void {
            log(tag, LEVEL_ERROR, message);
        }

        public static function log(tag:String, msgLevel:int, message:String):void {
            if (msgLevel < level) return;

            var levelStr:String;
            switch (msgLevel) {
                case LEVEL_DEBUG: levelStr = "DEBUG"; break;
                case LEVEL_INFO:  levelStr = "INFO";  break;
                case LEVEL_WARN:  levelStr = "WARN";  break;
                case LEVEL_ERROR: levelStr = "ERROR"; break;
                default:          levelStr = "LOG";   break;
            }

            var formatted:String = "[AqwApi:" + tag + "] " + message;

            if (printToConsole) {
                try {
                    trace(formatted);
                } catch (e:Error) {}
            }

            if (printToChat && msgLevel >= chatMinLevel) {
                pushChat(msgLevel >= LEVEL_WARN ? "warning" : "server", formatted);
            }

            if (onLog != null) {
                try {
                    onLog(tag, msgLevel, message);
                } catch (e:Error) {}
            }
        }

        public static function pushChat(type:String, text:String, sender:String = "API"):void {
            if (AqwApi.game != null && AqwApi.game.chatF != null && "pushMsg" in AqwApi.game.chatF) {
                try {
                    AqwApi.game.chatF.pushMsg(type, text, sender, "", 0);
                } catch (e:Error) {}
            }
        }
    }
}
