class Storage {
	public static function get(key:String):Dynamic {
		#if lua
		// Use MoneyMoney's LocalStorage if available
		if (untyped __lua__("LocalStorage")) {
			return untyped __lua__("LocalStorage[key]");
		} else {
			// Fallback to a regular table-based storage
			var storageTable:Dynamic = {};
			untyped __lua__("
				Storage = {
					__index = function(_, key)
						return storageTable[key]
					end,
					__newindex = function(_, key, value)
						storageTable[key] = value
					end
				}
				setmetatable(Storage, Storage)
			");
			return untyped __lua__("Storage[key]");
		}
		#else
		// Not in Lua context, return null
		return null;
		#end
	}

	public static function set(key:String, value:Dynamic):Void {
		#if lua
		// Use MoneyMoney's LocalStorage if available
		if (untyped __lua__("LocalStorage")) {
			untyped __lua__("LocalStorage[key] = value");
		} else {
			// Fallback to a regular table-based storage
			var storageTable:Dynamic = {};
			untyped __lua__("
				Storage = {
					__index = function(_, key)
						return storageTable[key]
					end,
					__newindex = function(_, key, value)
						storageTable[key] = value
					end
				}
				setmetatable(Storage, Storage)
			");
			untyped __lua__("Storage[key] = value");
		}
		#end
	}
}
