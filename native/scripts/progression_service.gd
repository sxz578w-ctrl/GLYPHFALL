extends RefCounted
class_name ProgressionService

const SITE_IDS: PackedStringArray = ["mirkwood", "sunken_grove"]
const TOTAL_STEPS: int = 7
const MAX_STAT: int = 999999

const QUEST_STEPS: Array[Dictionary] = [
    {
        "id": "discover_mirkwood",
        "kind": "discover",
        "site_id": "mirkwood",
        "title_ar": "إشارة غابة الظلال",
        "description_ar": "غادر الملاذ واتبع بوابة غابة الظلال حتى تدخل نطاقها.",
        "description_en": "Reach the Mirkwood Wilds entrance."
    },
    {
        "id": "clear_mirkwood",
        "kind": "clear",
        "site_id": "mirkwood",
        "title_ar": "تطهير غابة الظلال",
        "description_ar": "اهزم جميع الكائنات داخل غابة الظلال.",
        "description_en": "Defeat every hostile inside Mirkwood."
    },
    {
        "id": "restore_mirkwood",
        "kind": "restore",
        "site_id": "mirkwood",
        "title_ar": "إعادة إحياء المرساة الأولى",
        "description_ar": "اقترب من البلورة المركزية بعد تطهير الغابة، ثم أعد بناء المرساة مقابل 30 شظية.",
        "description_en": "Restore the Mirkwood anchor for 30 shards."
    },
    {
        "id": "discover_sunken_grove",
        "kind": "discover",
        "site_id": "sunken_grove",
        "title_ar": "نداء البستان الغارق",
        "description_ar": "اتبع الإشارة الزرقاء إلى البستان الغارق واكتشف مصدر الشذوذ.",
        "description_en": "Discover the Sunken Grove."
    },
    {
        "id": "clear_sunken_grove",
        "kind": "clear",
        "site_id": "sunken_grove",
        "title_ar": "إخماد الشذوذ",
        "description_ar": "اهزم جميع الحراس في البستان الغارق.",
        "description_en": "Defeat every hostile inside the Sunken Grove."
    },
    {
        "id": "restore_sunken_grove",
        "kind": "restore",
        "site_id": "sunken_grove",
        "title_ar": "إعادة تثبيت المرساة الثانية",
        "description_ar": "اقترب من البلورة المركزية وأعد بناء المرساة مقابل 30 شظية.",
        "description_en": "Restore the Sunken Grove anchor for 30 shards."
    },
    {
        "id": "return_haven",
        "kind": "return",
        "site_id": "",
        "title_ar": "العودة إلى الملاذ",
        "description_ar": "عد إلى الملاذ الآمن لتثبيت المراسي وإنهاء الرحلة الأولى.",
        "description_en": "Return to the safe haven."
    }
]

static func defaults() -> Dictionary:
    return {
        "discovered_sites": [],
        "cleared_sites": [],
        "restored_sites": [],
        "kills": 0,
        "deaths": 0,
        "play_time_seconds": 0.0,
        "campaign_complete": false
    }

static func normalise(raw_data: Variant) -> Dictionary:
    var result: Dictionary = defaults()
    if not raw_data is Dictionary:
        return result

    result["discovered_sites"] = _valid_sites(raw_data.get("discovered_sites", []))
    result["cleared_sites"] = _valid_sites(raw_data.get("cleared_sites", []))
    result["restored_sites"] = _valid_sites(raw_data.get("restored_sites", []))

    var discovered: Array = result["discovered_sites"]
    var cleared: Array = result["cleared_sites"]
    var restored: Array = result["restored_sites"]
    for site_id in cleared:
        if not discovered.has(site_id):
            discovered.append(site_id)
    for site_id in restored.duplicate():
        if not cleared.has(site_id):
            restored.erase(site_id)

    result["kills"] = clampi(int(raw_data.get("kills", 0)), 0, MAX_STAT)
    result["deaths"] = clampi(int(raw_data.get("deaths", 0)), 0, MAX_STAT)
    result["play_time_seconds"] = clampf(float(raw_data.get("play_time_seconds", 0.0)), 0.0, 315576000.0)
    result["campaign_complete"] = bool(raw_data.get("campaign_complete", false)) and _all_sites_restored(result)
    return result

static func mark_site_discovered(raw_data: Variant, site_id: String) -> Dictionary:
    var state := normalise(raw_data)
    _append_site(state["discovered_sites"], site_id)
    return state

static func mark_site_cleared(raw_data: Variant, site_id: String) -> Dictionary:
    var state := normalise(raw_data)
    if not SITE_IDS.has(site_id):
        return state
    _append_site(state["discovered_sites"], site_id)
    _append_site(state["cleared_sites"], site_id)
    return state

static func mark_site_restored(raw_data: Variant, site_id: String) -> Dictionary:
    var state := normalise(raw_data)
    if not SITE_IDS.has(site_id) or not state["cleared_sites"].has(site_id):
        return state
    _append_site(state["restored_sites"], site_id)
    state["campaign_complete"] = false
    return state

static func mark_returned_to_haven(raw_data: Variant) -> Dictionary:
    var state := normalise(raw_data)
    state["campaign_complete"] = _all_sites_restored(state)
    return state

static func is_site_discovered(raw_data: Variant, site_id: String) -> bool:
    var state := normalise(raw_data)
    return state["discovered_sites"].has(site_id)

static func is_site_cleared(raw_data: Variant, site_id: String) -> bool:
    var state := normalise(raw_data)
    return state["cleared_sites"].has(site_id)

static func is_site_restored(raw_data: Variant, site_id: String) -> bool:
    var state := normalise(raw_data)
    return state["restored_sites"].has(site_id)

static func is_campaign_complete(raw_data: Variant) -> bool:
    return bool(normalise(raw_data)["campaign_complete"])

static func current_objective(raw_data: Variant) -> Dictionary:
    var state := normalise(raw_data)
    for index in range(QUEST_STEPS.size()):
        var step: Dictionary = QUEST_STEPS[index]
        if not _is_step_complete(state, step):
            var objective: Dictionary = step.duplicate(true)
            objective["number"] = index + 1
            objective["total"] = TOTAL_STEPS
            return objective
    return {
        "id": "campaign_complete",
        "kind": "complete",
        "site_id": "",
        "title_ar": "الرحلة الأولى اكتملت",
        "description_ar": "عادت المراسي إلى العمل. استكشف العالم واجمع الشظايا وطوّر بطلك.",
        "description_en": "The first frontier expedition is complete.",
        "number": TOTAL_STEPS,
        "total": TOTAL_STEPS
    }

static func completed_steps(raw_data: Variant) -> int:
    var state := normalise(raw_data)
    var count: int = 0
    for step in QUEST_STEPS:
        if _is_step_complete(state, step):
            count += 1
    return count

static func record_kill(raw_data: Variant) -> Dictionary:
    var state := normalise(raw_data)
    state["kills"] = mini(MAX_STAT, int(state["kills"]) + 1)
    return state

static func record_death(raw_data: Variant) -> Dictionary:
    var state := normalise(raw_data)
    state["deaths"] = mini(MAX_STAT, int(state["deaths"]) + 1)
    return state

static func add_play_time(raw_data: Variant, seconds: float) -> Dictionary:
    var state := normalise(raw_data)
    state["play_time_seconds"] = clampf(float(state["play_time_seconds"]) + maxf(0.0, seconds), 0.0, 315576000.0)
    return state

static func _valid_sites(raw_sites: Variant) -> Array:
    var result: Array = []
    if not raw_sites is Array:
        return result
    for value in raw_sites:
        var site_id := str(value)
        if SITE_IDS.has(site_id) and not result.has(site_id):
            result.append(site_id)
    return result

static func _append_site(target: Array, site_id: String) -> void:
    if SITE_IDS.has(site_id) and not target.has(site_id):
        target.append(site_id)

static func _all_sites_restored(state: Dictionary) -> bool:
    for site_id in SITE_IDS:
        if not state["restored_sites"].has(site_id):
            return false
    return true

static func _is_step_complete(state: Dictionary, step: Dictionary) -> bool:
    var site_id := str(step.get("site_id", ""))
    match str(step.get("kind", "")):
        "discover":
            return state["discovered_sites"].has(site_id)
        "clear":
            return state["cleared_sites"].has(site_id)
        "restore":
            return state["restored_sites"].has(site_id)
        "return":
            return bool(state["campaign_complete"])
    return false
