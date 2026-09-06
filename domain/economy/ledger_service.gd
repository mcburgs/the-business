extends RefCounted

const LEDGER_KEY: String = "ledger_v1"

func ensure_ledger(world_state: Dictionary) -> Dictionary:
    if not world_state.has(LEDGER_KEY):
        world_state[LEDGER_KEY] = {"schema_version": 1, "accounts": {}, "transactions": []}
    return world_state[LEDGER_KEY]

func post(world_state: Dictionary, transaction: Dictionary) -> Dictionary:
    var validation: Dictionary = validate_transaction(transaction)
    if not bool(validation["passed"]):
        return validation
    var ledger: Dictionary = ensure_ledger(world_state)
    var candidate: Dictionary = ledger.duplicate(true)
    var transactions: Array = candidate.get("transactions", [])
    var transaction_id: String = str(transaction.get("transaction_id", ""))
    for existing: Variant in transactions:
        if existing is Dictionary and str((existing as Dictionary).get("transaction_id", "")) == transaction_id:
            return _failure("LEDGER001", "transaction.transaction_id", {"reason": "duplicate", "transaction_id": transaction_id})
    transactions.append(transaction.duplicate(true))
    candidate["transactions"] = transactions
    var accounts: Dictionary = candidate.get("accounts", {})
    for posting_value: Variant in transaction.get("postings", []):
        var posting: Dictionary = posting_value
        var account_id: String = str(posting["account_id"])
        var currency_id: String = str(posting["currency_id"])
        var key: String = account_id + "|" + currency_id
        accounts[key] = int(accounts.get(key, 0)) + int(posting["minor_units"])
    candidate["accounts"] = accounts
    world_state[LEDGER_KEY] = candidate
    return {"passed": true, "errors": [], "transaction_id": transaction_id}

func validate_transaction(transaction: Dictionary) -> Dictionary:
    var transaction_id: String = str(transaction.get("transaction_id", ""))
    if transaction_id.is_empty():
        return _failure("LEDGER001", "transaction.transaction_id", {"reason": "required"})
    if not transaction.get("postings", null) is Array or (transaction.get("postings") as Array).size() < 2:
        return _failure("LEDGER001", "transaction.postings", {"reason": "at_least_two_postings_required"})
    var totals: Dictionary = {}
    var postings: Array = transaction["postings"]
    for index: int in range(postings.size()):
        if not postings[index] is Dictionary:
            return _failure("LEDGER001", "transaction.postings[" + str(index) + "]", {"reason": "object_required"})
        var posting: Dictionary = postings[index]
        var account_id: String = str(posting.get("account_id", ""))
        var currency_id: String = str(posting.get("currency_id", ""))
        if account_id.is_empty() or currency_id.is_empty() or not posting.get("minor_units") is int:
            return _failure("LEDGER001", "transaction.postings[" + str(index) + "]", {"reason": "account_currency_integer_minor_units_required"})
        totals[currency_id] = int(totals.get(currency_id, 0)) + int(posting["minor_units"])
    for currency: Variant in totals.keys():
        if int(totals[currency]) != 0:
            return _failure("LEDGER001", "transaction.postings", {"reason": "unbalanced", "currency_id": currency, "net_minor_units": totals[currency]})
    return {"passed": true, "errors": []}

func validate_ledger(world_state: Dictionary) -> Dictionary:
    if not world_state.has(LEDGER_KEY):
        return {"passed": true, "errors": []}
    var ledger_value: Variant = world_state[LEDGER_KEY]
    if not ledger_value is Dictionary:
        return _failure("LEDGER001", "world_state." + LEDGER_KEY, {"reason": "object_required"})
    var ledger: Dictionary = ledger_value
    if int(ledger.get("schema_version", -1)) != 1 or not ledger.get("accounts", null) is Dictionary or not ledger.get("transactions", null) is Array:
        return _failure("LEDGER001", "world_state." + LEDGER_KEY, {"reason": "invalid_ledger_shape"})
    var rebuilt: Dictionary = {}
    for index: int in range((ledger["transactions"] as Array).size()):
        var transaction: Dictionary = ledger["transactions"][index]
        var validation: Dictionary = validate_transaction(transaction)
        if not bool(validation["passed"]):
            return validation
        for posting_value: Variant in transaction["postings"]:
            var posting: Dictionary = posting_value
            var key: String = str(posting["account_id"]) + "|" + str(posting["currency_id"])
            rebuilt[key] = int(rebuilt.get(key, 0)) + int(posting["minor_units"])
    if rebuilt != ledger["accounts"]:
        return _failure("LEDGER001", "world_state." + LEDGER_KEY + ".accounts", {"reason": "account_totals_do_not_reconcile"})
    return {"passed": true, "errors": []}

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
