extends RefCounted

const LedgerService = preload("res://domain/economy/ledger_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var world: Dictionary = {}
    var ledger: RefCounted = LedgerService.new()
    var valid: Dictionary = {
        "transaction_id": "ledger_tx:0001",
        "occurred_on": "2001-02-01",
        "source": {"entity_id": "promotion:PRO00001", "event_id": "event:E000000001"},
        "postings": [
            {"account_id": "asset.cash", "minor_units": 12500, "currency_id": "currency.fixture"},
            {"account_id": "equity.offset", "minor_units": -12500, "currency_id": "currency.fixture"},
        ],
    }
    var accepted: Dictionary = ledger.call("post", world, valid)
    if not bool(accepted["passed"]): failures.append("valid reconciled ledger transaction should be accepted")
    var before: Dictionary = world.duplicate(true)
    var invalid: Dictionary = valid.duplicate(true)
    invalid["transaction_id"] = "ledger_tx:0002"
    invalid["postings"] = [{"account_id": "asset.cash", "minor_units": 99, "currency_id": "currency.fixture"}, {"account_id": "equity.offset", "minor_units": -98, "currency_id": "currency.fixture"}]
    var rejected: Dictionary = ledger.call("post", world, invalid)
    if bool(rejected["passed"]): failures.append("unbalanced transaction must be rejected")
    if world != before: failures.append("rejected ledger transaction must not partially mutate retained ledger state")
    if not bool(ledger.call("validate_ledger", world)["passed"]): failures.append("retained ledger must reconcile after valid posting")
    return {"name": "phase_d_ledger", "passed": failures.is_empty(), "failures": failures}
