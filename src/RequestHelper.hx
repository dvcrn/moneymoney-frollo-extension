import haxe.Http;
import lua.Table;

class RequestHelper {
	public static function makeRequest(url:String, method:String, headers:Map<String, String>, body:String = null):{
		mimeType:String,
		charset:String,
		headers:Map<String, Null<String>>,
		content:String
	} {
		#if lua
		// Use MoneyMoney's Connection object if available
		if (untyped __lua__("Connection")) {
			var connection = untyped __lua__("Connection()");
			var requestMethod = method.toUpperCase();
			var content:String = null;
			var charset:String = null;
			var mimeType:String = null;
			var filename:String = null;
			var responseHeaders:Map<String, String> = null;

			var headers = Table.fromMap(headers);

			trace("making request to: " + url);
			trace(headers);
			trace(body);

			if (requestMethod == "GET") {
				untyped __lua__("content, charset, mimeType, filename, responseHeaders = connection:request(method, url, nil, headers['Content-Type'], headers)");
			} else if (requestMethod == "POST") {
				untyped __lua__("content, charset, mimeType, filename, responseHeaders = connection:request(method, url, body, headers['Content-Type'], headers)");
			} else {
				throw 'Unsupported HTTP method: $method';
			}

			untyped __lua__("
           for k, v in pairs(responseHeaders) do
               print('  ' .. k .. ': ' .. v)
           end");

			// cast the response headers to a lua.Table
			// var responseHeaders = Table.fromMap(responseHeaders);

			// var t = Table.fromMap(responseHeaders);
			// var to:haxe.DynamicAccess<String> = Table.toObject(t);

			// trace(t);
			// trace(to);
			// trace(Table.toMap(t));

			// var contentType = to["Content-Type"];
			// trace(parsedHeaders);

			return {
				headers: responseHeaders,
				content: content,
				charset: charset,
				mimeType: mimeType,
			};
		} else {
			throw "Connection object is not available in the current environment";
		}
		#else
		throw "HTTP requests are only supported in the Lua environment";
		#end
	}
}
