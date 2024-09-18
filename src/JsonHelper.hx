class JsonHelper {
	public static function parse(jsonString:String):Dynamic {
		#if lua
		// Use MoneyMoney's JSON object if available
		if (untyped __lua__("JSON")) {
			return untyped __lua__("JSON(jsonString):dictionary()");
		} else {
			// Fallback to haxe.Json if JSON is not available
			return haxe.Json.parse(jsonString);
		}
		#else
		return haxe.Json.parse(jsonString);
		#end
	}

	public static function stringify(data:Dynamic, ?args:Dynamic):String {
		return haxe.Json.stringify(data, args);

		#if lua
		// Use MoneyMoney's JSON object if available
		if (untyped __lua__("JSON")) {
			trace("using moneymoney json parser");
			return untyped __lua__("JSON():set(data):json()");
		} else {
			// Fallback to haxe.Json if JSON is not available
			return haxe.Json.stringify(data, args);
		}
		#else
		return haxe.Json.stringify(data, args);
		#end
	}
}
