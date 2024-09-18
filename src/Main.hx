import lua.Table;
import RequestHelper;
import JsonHelper;
import Frollo;
import Storage;

enum abstract AccountType(String) {
	var AccountTypeGiro = "AccountTypeGiro";
	var AccountTypeSavings = "AccountTypeSavings";
	var AccountTypeFixedTermDeposit = "AccountTypeFixedTermDeposit";
	var AccountTypeLoan = "AccountTypeLoan";
	var AccountTypeCreditCard = "AccountTypeCreditCard";
	var AccountTypePortfolio = "AccountTypePortfolio";
	var AccountTypeOther = "AccountTypeOther";
}

typedef Account = {
	?name:String,
	?owner:String,
	?accountNumber:String,
	?subAccount:String,
	?portfolio:Bool,
	?bankCode:String,
	?currency:String,
	?iban:String,
	?bic:String,
	?balance:Float,
	type:AccountType
}

typedef Transaction = {
	?name:String,
	?accountNumber:String,
	?bankCode:String,
	?amount:Float,
	?currency:String,
	?bookingDate:Int,
	?valueDate:Int,
	?purpose:String,
	?transactionCode:Int,
	?textKeyExtension:Int,
	?purposeCode:String,
	?bookingKey:String,
	?bookingText:String,
	?primanotaNumber:String,
	?batchReference:String,
	?endToEndReference:String,
	?mandateReference:String,
	?creditorId:String,
	?returnReason:String,
	?booked:Bool
}

typedef Security = {
	?name:String,
	?isin:String,
	?securityNumber:String,
	?quantity:Float,
	?currencyOfQuantity:String,
	?purchasePrice:Float,
	?currencyOfPurchasePrice:String,
	?exchangeRateOfPurchasePrice:Float,
	?price:Float,
	?currencyOfPrice:String,
	?exchangeRateOfPrice:Float,
	?amount:Float,
	?originalAmount:Float,
	?currencyOfOriginalAmount:String,
	?market:String,
	?tradeTimestamp:Int
}

class Main {
	static function getAccountType(frolloAccountType:String):AccountType {
		return switch (frolloAccountType.toLowerCase()) {
			case "bank_account": AccountType.AccountTypeGiro;
			case "savings": AccountType.AccountTypeSavings;
			case "emergency_fund": AccountType.AccountTypeSavings;
			case "term_deposit": AccountType.AccountTypeFixedTermDeposit;
			case "offset": AccountType.AccountTypeGiro;
			case "credit_card": AccountType.AccountTypeCreditCard;
			case "balance_transfer_card": AccountType.AccountTypeCreditCard;
			case "rewards_card": AccountType.AccountTypeCreditCard;
			case "super_annuation": AccountType.AccountTypeOther;
			case "shares": AccountType.AccountTypePortfolio;
			case "business": AccountType.AccountTypeGiro;
			case "bonds": AccountType.AccountTypePortfolio;
			case "mortgage": AccountType.AccountTypeLoan;
			case "personal": AccountType.AccountTypeLoan;
			case "insurance": AccountType.AccountTypeOther;
			case "line_of_credit": AccountType.AccountTypeLoan;
			default: AccountType.AccountTypeOther;
		}
	}

	@:luaDotMethod
	@:expose("SupportsBank")
	static function SupportsBank(protocol:String, bankCode:String) {
		trace("SupportsBank got called");
		trace(protocol);
		trace(bankCode);

		return bankCode == "Frollo";
	}

	@:luaDotMethod
	@:expose("InitializeSession")
	static function InitializeSession(protocol:String, bankCode:String, username:String, reserved, password:String) {
		trace("InitializeSession got called");
		trace(protocol);
		trace(bankCode);
		trace(username);
		trace(reserved);
		trace(password);

		var token = Storage.get("access_token");
		var token_expiration:Int = Storage.get("token_expiration");
		trace("localstorage token -- " + token);
		trace("localstorage token expiration -- " + token_expiration);
		trace("now -- " + Date.now().getTime());
		if (token == null || token_expiration == null || Date.now().getTime() > token_expiration) {
			trace("Login??");
			var loginResponse = Frollo.login(username, password);
			trace(loginResponse);
			token = loginResponse.access_token;
			var token_crated = loginResponse.created_at; // timestamp
			var token_expires_in = loginResponse.expires_in; // seconds
			token_expiration = token_crated + token_expires_in; // timestamp

			Storage.set("access_token", token);
			Storage.set("token_expiration", token_expiration);
		}
	}

	@:luaDotMethod
	@:expose("ListAccounts")
	static function ListAccounts(knownAccounts) {
		trace("ListAccounts got called");
		trace(knownAccounts);
		var token = Storage.get("access_token");
		trace("token -- " + token);

		var accountsResponse = Frollo.getAccounts(token);
		trace("accountsResponse---");
		trace(accountsResponse);

		var accounts:Array<Account> = [];
		for (frolloAccount in accountsResponse) {
			var account:Account = {
				name: frolloAccount.account_name + " (" + frolloAccount.provider.name + ")",
				accountNumber: Std.string(frolloAccount.id),
				currency: frolloAccount.current_balance.currency,
				balance: Std.parseFloat(frolloAccount.current_balance.amount),
				type: getAccountType(frolloAccount.account_attributes.account_type)
			};
			accounts.push(account);
		}

		var results = Table.fromArray(accounts);

		trace(results);

		return results;
	}

	@:luaDotMethod
	@:expose("RefreshAccount")
	static function RefreshAccount(account:{
		iban:String,
		bic:String,
		comment:String,
		bankCode:String,
		owner:String,
		attributes:Dynamic,
		subAccount:String,
		currency:String,
		name:String,
		balance:Float,
		portfolio:Bool,
		type:String,
		balanceDate:Float,
		accountNumber:String
	}, since:Float) {
		trace("RefreshAccount got called");
		trace(account);
		trace(since);
		var token = Storage.get("access_token");
		trace("token -- " + token);

		// conver to
		var date = Date.fromTime(since * 1000);
		var sinceStr = DateTools.format(date, "%Y-%m-%d");
		trace(sinceStr);

		var acc = Frollo.getAccount(token, account.accountNumber);
		trace("account ---");
		trace(acc);

		var txs = Frollo.getTransactions(token, account.accountNumber, sinceStr);
		trace("transactions ---");
		trace(txs);

		var transactions:Array<Transaction> = [];
		for (frolloTx in txs) {
			trace("parsing...");
			trace(frolloTx);
			var transaction:Transaction = {
				name: frolloTx.description.original,
				accountNumber: Std.string(frolloTx.account_id),
				amount: Std.parseFloat(frolloTx.amount.amount),
				currency: frolloTx.amount.currency,
				bookingDate: Std.parseInt(DateTools.format(Date.fromString(frolloTx.transaction_date), "%s")),
				// valueDate: Std.parseInt(DateTools.format(Date.fromString(frolloTx.transaction_date), "%s")),
				purpose: frolloTx.description.simple,
				booked: frolloTx.status == "posted"
			};
			transactions.push(transaction);
		}

		trace(transactions);

		return {
			balance: acc.current_balance.amount,
			transactions: Table.fromArray(transactions),
		}
	}

	@:luaDotMethod
	@:expose("EndSession")
	static function EndSession() {
		trace("EndSession got called");
	}

	function nonstatic() {
		trace("ooooo");
	}

	static function main() {
		trace("hello world");
		untyped __lua__("
        WebBanking {
            version = 1.0,
            url = 'https://ana.co.jp',
            description = 'Frollo',
            services = { 'Frollo' },
        }
        ");

		untyped __lua__("
        function SupportsBank(protocol, bankCode)
            return _hx_exports.SupportsBank(protocol, bankCode)
        end
        ");

		untyped __lua__("
        function InitializeSession(protocol, bankCode, username, reserved, password)
            return _hx_exports.InitializeSession(protocol, bankCode, username, reserved, password)
        end
        ");

		untyped __lua__("
        function RefreshAccount(account, since)
            return _hx_exports.RefreshAccount(account, since)
        end
        ");

		untyped __lua__("
        function ListAccounts(knownAccounts)
            return _hx_exports.ListAccounts(knownAccounts)
        end
        ");

		untyped __lua__("
        function EndSession()
            return _hx_exports.EndSession()
        end
        ");
	}
}
