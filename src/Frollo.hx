import RequestHelper;
import JsonHelper;
import lua.Table;

typedef LoginResponse = {
	access_token:String,
	token_type:String,
	expires_in:Int,
	refresh_token:String,
	scope:String,
	created_at:Int,
	id_token:String
}

typedef FrolloAccount = {
	id:Int,
	aggregator:String,
	external_id:String,
	provider_account_id:Int,
	provider:{
		id:Int, name:String, small_logo_url:String, large_logo_url:String
	},
	account_name:String,
	account_status:String,
	joint_account:Bool,
	owner_type:String,
	account_attributes:{
		container:String, account_type:String, group:String, classification:String
	},
	included:Bool,
	favourite:Bool,
	hidden:Bool,
	primary_balance:{
		amount:String, currency:String
	},
	current_balance:{
		amount:String, currency:String
	},
	refresh_status:{
		status:String, sub_status:String, last_refreshed:String, next_refresh:String
	},
	products_available:Bool,
	asset:Bool,
	payids:Array<Dynamic>
}

typedef FrolloTransaction = {
	id:Int,
	account_id:Int,
	account_aggregator:String,
	base_type:String,
	status:String,
	included:Bool,
	transaction_date:String,
	post_date:String,
	amount:{
		amount:String, currency:String
	},
	description:{
		original:String, simple:String
	},
	budget_category:String,
	category:{
		id:Int, name:String, display_name:String, colour:String, image:{
			id:Int, small_image_url:String, large_image_url:String
		}
	},
	merchant:{
		id:Int, name:String, merchant_type:String, image_url:String, phone:String, website:String
	},
	user_tags:Array<Dynamic>,
	reference:String,
	type:String
}

typedef GetTransactionsResponse = {
	data:Array<FrolloTransaction>,
	paging:{
		cursors:{
			before:Null<String>, after:Null<String>
		}, total:Int
	}
}

class Frollo {
	static var CLIENT_ID = "UCyPI63qO8fVsjnxNcEuVbHDOWSr8tQiDTrFsrb93o0";

	public static function login(username:String, password:String):LoginResponse {
		var url = "https://id.frollo.us/oauth/token";
		var method = "POST";
		var headers = ["Accept" => "application/json", "Content-Type" => "application/json"];
		var body = JsonHelper.stringify({
			grant_type: "password",
			domain: "api.frollo.us",
			client_id: CLIENT_ID,
			username: username,
			password: password,
			scope: "offline_access email openid"
		});

		trace("stringified body");
		trace(body);

		var response = RequestHelper.makeRequest(url, method, headers, body);
		return cast JsonHelper.parse(response.content);
	}

	public static function getAccounts(accessToken:String):Array<FrolloAccount> {
		var url = "https://api.frollo.us/api/v2/aggregation/accounts";
		var method = "GET";
		var headers = [
			"Authorization" => "Bearer " + accessToken,
			"X-Api-Version" => "2.26",
			"X-Bundle-Id" => "us.frollo.frollosdk",
			"X-Device-Version" => "Android12",
			"X-Software-Version" => "SDK3.28.0-B3270|APP2.26.0-B104594",
			"Host" => "api.frollo.us",
			"Connection" => "Keep-Alive",
			"User-Agent" => "okhttp/4.12.0",
			"Content-type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, method, headers);
		return Table.toArray(JsonHelper.parse(response.content));
	}

	public static function getTransactions(accessToken:String, accountId:String, ?fromDate:String, ?toDate:String):Array<FrolloTransaction> {
		var url = 'https://api.frollo.us/api/v2/aggregation/transactions?account_ids=${accountId}&size=150';
		if (fromDate != null) {
			url += '&from_date=${fromDate}';
		}
		if (toDate != null) {
			url += '&to_date=${toDate}';
		}
		var method = "GET";
		var headers = [
			"Authorization" => "Bearer " + accessToken,
			"X-Api-Version" => "2.26",
			"X-Bundle-Id" => "us.frollo.frollosdk",
			"X-Device-Version" => "Android12",
			"X-Software-Version" => "SDK3.28.0-B3270|APP2.26.0-B104594",
			"Host" => "api.frollo.us",
			"Connection" => "Keep-Alive",
			"User-Agent" => "okhttp/4.12.0"
		];

		var response = RequestHelper.makeRequest(url, method, headers);
		var parsedContent = JsonHelper.parse(response.content);
		var parsedTable = Table.toArray(parsedContent.data);

		trace(parsedTable.length);

		if (parsedTable.length == 0) {
			return [];
		}

		return parsedTable;
	}

	public static function getAccount(accessToken:String, accountId:String):FrolloAccount {
		var url = 'https://api.frollo.us/api/v2/aggregation/accounts/${accountId}';
		var method = "GET";
		var headers = [
			"Authorization" => "Bearer " + accessToken,
			"X-Api-Version" => "2.26",
			"X-Bundle-Id" => "us.frollo.frollosdk",
			"X-Device-Version" => "Android12",
			"X-Software-Version" => "SDK3.28.0-B3270|APP2.26.0-B104594",
			"Host" => "api.frollo.us",
			"Connection" => "Keep-Alive",
			"User-Agent" => "okhttp/4.12.0"
		];

		var response = RequestHelper.makeRequest(url, method, headers);
		return cast JsonHelper.parse(response.content);
	}

	public static function syncAccounts(accessToken:String):Dynamic {
		var url = 'https://api.frollo.us/api/v2/aggregation/provideraccounts/sync';
		var method = "POST";
		var headers = [
			"Authorization" => "Bearer " + accessToken,
			"X-Api-Version" => "2.26",
			"X-Bundle-Id" => "us.frollo.frollosdk",
			"X-Device-Version" => "Android12",
			"X-Software-Version" => "SDK3.28.0-B3270|APP2.26.0-B104594",
			"Host" => "api.frollo.us",
			"Connection" => "Keep-Alive",
			"User-Agent" => "okhttp/4.12.0"
		];

		var response = RequestHelper.makeRequest(url, method, headers, "");
		trace(response.content);

		return JsonHelper.parse(response.content);
	}
}
