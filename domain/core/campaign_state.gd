extends RefCounted

const OwnershipSeatState = preload("res://domain/core/ownership_seat_state.gd")
const EventState = preload("res://domain/events/event_state.gd")
const RandomState = preload("res://domain/core/random_state.gd")
const VictoryState = preload("res://domain/core/victory_state.gd")

const STATE_SCHEMA_VERSION: int = 2

var state_schema_version: int = STATE_SCHEMA_VERSION
var campaign_pack_id: String = ""
var campaign_pack_version: String = ""
var content_fingerprint: String = ""
var ruleset_id: String = ""
var current_date: String = ""
var turn_number: int = 0
var ownership_seat: RefCounted = OwnershipSeatState.new()
var world_state: Dictionary = {}

var people: Dictionary = {}
var promotions: Dictionary = {}
var markets: Dictionary = {}
var regions: Dictionary = {}
var touring_companies: Dictionary = {}
var contracts: Dictionary = {}
var championships: Dictionary = {}
var programs: Dictionary = {}
var media_deals: Dictionary = {}
var venues: Dictionary = {}
var agreements: Dictionary = {}
var relationships: Dictionary = {}
var knowledge_bases: Dictionary = {}

var event_state: RefCounted = EventState.new()
var rng_state: RefCounted = RandomState.new()
var victory_state: RefCounted = VictoryState.new()

func store_by_name(store_name: String) -> Dictionary:
    match store_name:
        "people": return people
        "promotions": return promotions
        "markets": return markets
        "regions": return regions
        "touring_companies": return touring_companies
        "contracts": return contracts
        "championships": return championships
        "programs": return programs
        "media_deals": return media_deals
        "venues": return venues
        "agreements": return agreements
        "relationships": return relationships
        "knowledge_bases": return knowledge_bases
        _: return {}
