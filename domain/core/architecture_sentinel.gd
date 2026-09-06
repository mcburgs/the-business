extends RefCounted

const LAYER: String = "simulation_domain"
const PURPOSE: String = "Phase A dependency-boundary sentinel; not gameplay state."

func describe() -> Dictionary:
    return {
        "layer": LAYER,
        "purpose": PURPOSE,
    }
