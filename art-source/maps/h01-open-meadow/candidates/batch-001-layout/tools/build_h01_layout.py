from __future__ import annotations

import hashlib
import importlib.util
import json
import math
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import deque
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from PIL import Image, ImageChops, ImageDraw, ImageFont


SCRIPT_PATH = Path(__file__).resolve()
BATCH_ROOT = SCRIPT_PATH.parents[1]
REPO_ROOT = SCRIPT_PATH.parents[6]
BASE_SCRIPT = (
    REPO_ROOT
    / "art-source/maps/h02-braided-river/candidates/batch-001-layout/tools/build_h02_layout.py"
)

spec = importlib.util.spec_from_file_location("estate_layout_base_h02", BASE_SCRIPT)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot import pipeline donor: {BASE_SCRIPT}")
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

TILE = 32
MAP_W = 128
MAP_H = 96
CELL_COUNT = MAP_W * MAP_H
TERRAIN_FIRST_GID = 1
OBJECT_FIRST_GID = 257
ARCH_FIRST_GID = 513
LOGIC_FIRST_GID = 1025
LOGIC_FISH_ECOLOGY_POND_BROOK = 12
LOGIC_FISH_ECOLOGY_SOUTH_STREAM = 13
STATUS = "h01_layout_candidate_batch_001"
BATCH_ID = "h01_open_meadow_layout_batch_001"
MAP_ID = "home_h01_open_meadow"
HOME_ORIGIN = (60, 24)
HOME_SPAWN = (63, 31)
PORTALS = {
    "portal_village_west": (1, 49),
    "portal_wilderness_east": (126, 55),
    "portal_future_region_south": (64, 94),
}
H01_REQUIRED_LAYERS = (
    "Ground", "Ground_Detail", "Water", "Path", "Objects_Back",
    "Development_Derelict_Back", "Development_Derelict", "Development_Derelict_PathHint", "Development_Reclaimed_Back",
    "Development_Reclaimed", "Development_Expanded_Back", "Development_Expanded",
    "Development_Mature", "Characters", "Development_Derelict_Front", "Objects_Front",
    "Development_Reclaimed_Front", "Development_Expanded_Front", "Effects",
    "Season_Spring", "Season_Summer", "Season_Autumn", "Season_Winter",
    "Anomaly_Light", "Anomaly_Medium", "Bridge_Mask", "Mask_Collision_Water",
    "Mask_Farmable", "Mask_Buildable_Free", "Mask_Buildable_Reserved", "Mask_NoBuild",
    "Portal_Future_Region_Locked_Visual", "Mask_Crossing_Development_Reclaimed", "Mask_Fishing_Ecology_PondBrook",
    "Mask_Fishing_Ecology_SouthStream",
)
H01_REQUIRED_OBJECT_GROUPS = (
    "Collision", "Farmable", "Buildable_Free", "Buildable_Reserved", "NoBuild",
    "Spawn", "Portal", "NpcAnchor", "Interaction", "StoryTrigger", "ResourceSpawnZone",
    "SeasonalResourceZone", "FishingEcologyZone", "FishingAccessQA", "Occlusion",
    "AnomalyStateAnchor",
)

for name, value in {
    "TILE": TILE,
    "MAP_W": MAP_W,
    "MAP_H": MAP_H,
    "CELL_COUNT": CELL_COUNT,
    "STATUS": STATUS,
    "BATCH_ID": BATCH_ID,
    "MAP_ID": MAP_ID,
    "HOME_ORIGIN": HOME_ORIGIN,
    "HOME_SPAWN": HOME_SPAWN,
    "PORTALS": PORTALS,
}.items():
    setattr(base, name, value)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def grid() -> list[int]:
    return [0] * CELL_COUNT


def idx(point: tuple[int, int]) -> int:
    return point[1] * MAP_W + point[0]


def prepare_tilesets() -> list[Path]:
    base.copy_tilesets(BATCH_ROOT, REPO_ROOT)
    root = BATCH_ROOT / "source/tilesets"
    outputs: list[Path] = []
    for kind in ("terrain", "objects", "architecture", "logic"):
        old_png = root / f"h02_layout_{kind}.png"
        old_tsx = root / f"h02_layout_{kind}.tsx"
        new_png = root / f"h01_layout_{kind}.png"
        new_tsx = root / f"h01_layout_{kind}.tsx"
        old_png.replace(new_png)
        tree = ET.parse(old_tsx)
        tsx = tree.getroot()
        tsx.attrib["name"] = f"h01_layout_{kind}"
        image = tsx.find("image")
        if image is None:
            raise RuntimeError(f"Missing image in {old_tsx}")
        image.attrib["source"] = new_png.name
        base.set_property(tsx, "assetStatus", STATUS)
        base.set_property(tsx, "artCandidateBatch", BATCH_ID)
        base.set_property(tsx, "targetMapId", MAP_ID)
        base.set_property(tsx, "artRole", "shared_estate_layout_visual_language")
        base.set_property(tsx, "h02SpecificPixelPass", False)
        if kind == "terrain":
            tile = tsx.find("tile[@id='72']")
            if tile is not None:
                tile.attrib["class"] = "meadow_stone_crossing"
                base.set_property(tile, "region", "h01_open_meadow")
                base.set_property(tile, "walkable", True)
                base.set_property(tile, "fishable", False)
        elif kind == "logic":
            logic_image = Image.open(new_png).convert("RGBA")
            draw = ImageDraw.Draw(logic_image)
            for tile_id, color in (
                (LOGIC_FISH_ECOLOGY_POND_BROOK, (64, 174, 196, 220)),
                (LOGIC_FISH_ECOLOGY_SOUTH_STREAM, (52, 126, 168, 220)),
            ):
                left = tile_id * TILE
                draw.rectangle((left + 2, 2, left + 29, 29), fill=color, outline=(235, 240, 232, 255), width=1)
                draw.ellipse((left + 8, 10, left + 23, 21), outline=(19, 44, 54, 255), width=2)
            logic_image.save(new_png)
            base.add_tileset_tile(
                tsx,
                LOGIC_FISH_ECOLOGY_POND_BROOK,
                "fishing_ecology_pond_brook",
                {
                    "semanticId": "fish_ecology.h01.pond_brook",
                    "godotDisposition": "custom_data:fishing_ecology_zone",
                    "operation": "set_profile",
                },
            )
            crossing_tile = tsx.find(f"tile[@id='{base.LOGIC_CROSSING_OVERRIDE}']")
            if crossing_tile is None:
                raise RuntimeError("H01 logic tileset is missing crossing_override")
            base.set_property(crossing_tile, "godotDisposition", "water_authority:remove_collision_fishable_and_ecology_when_state_active")
            base.set_property(crossing_tile, "operation", "remove_water_collision_fishable_and_ecology_when_active")
            base.set_property(crossing_tile, "removesFishableEligibility", True)
            base.set_property(crossing_tile, "removesFishingEcologyProfile", True)
            base.add_tileset_tile(
                tsx,
                LOGIC_FISH_ECOLOGY_SOUTH_STREAM,
                "fishing_ecology_south_stream",
                {
                    "semanticId": "fish_ecology.h01.south_stream",
                    "godotDisposition": "custom_data:fishing_ecology_zone",
                    "operation": "set_profile",
                },
            )
        ET.indent(tree, space="  ")
        tree.write(new_tsx, encoding="utf-8", xml_declaration=True)
        old_tsx.unlink()
        outputs.extend((new_png, new_tsx))
    return outputs


def build_layout() -> dict[str, Any]:
    all_cells = {(x, y) for y in range(MAP_H) for x in range(MAP_W)}

    water = base.polyline_cells(
        [(-3, 84), (18, 83), (39, 86), (61, 85), (83, 87), (105, 84), (131, 86)],
        2.55,
    )
    pond = base.circle_cells(100, 39, 6.2) | base.circle_cells(96, 41, 4.0)
    pond_brook = base.polyline_cells([(98, 45), (103, 56), (99, 68), (92, 84)], 1.25)
    water |= pond | pond_brook
    protected_land = (
        base.rect_cells(0, 45, 8, 9)
        | base.rect_cells(120, 51, 8, 9)
        | base.rect_cells(59, 90, 11, 6)
        | base.rect_cells(57, 21, 14, 17)
    )
    water -= protected_land
    water.add((94, 83))

    west_route = base.thin_line([(1, 49), (26, 49), (45, 43), (63, 31)], 2)
    east_route = base.thin_line([(63, 31), (78, 36), (91, 48), (108, 53), (126, 55)], 2)
    south_route = base.thin_line([(63, 31), (62, 50), (64, 69), (64, 94)], 2)
    pond_route = base.thin_line([(78, 36), (88, 37), (93, 39)], 1)
    path_base = (west_route | east_route | south_route | pond_route) & all_cells
    permanent_crossings = path_base & water
    west_development_points = [(31, 61), (48, 61), (62, 55)]
    east_development_points = [(78, 65), (96, 67), (110, 64)]
    development_centerlines = (
        base.raster_line(west_development_points)
        | base.raster_line(east_development_points)
    )
    development_area = (
        base.thin_line(west_development_points, 1)
        | base.thin_line(east_development_points, 1)
        | development_centerlines
    ) & all_cells
    unlockable_path = ((development_area - water) | (development_centerlines & water)) & all_cells
    unlockable_crossings = unlockable_path & water

    land = all_cells - water
    shoreline = {p for p in land if any(n in water for n in base.neighbors4(p))}
    shore_buffer = shoreline | {n for p in shoreline for n in base.neighbors4(p) if n in land}

    home_footprint = base.rect_cells(HOME_ORIGIN[0], HOME_ORIGIN[1], 7, 5)
    home_safety = base.circle_cells(HOME_SPAWN[0], HOME_SPAWN[1], 5.2)
    utility_footprint = base.rect_cells(28, 64, 4, 3)
    pump_footprint = base.rect_cells(91, 39, 3, 3)
    fixed_footprints = home_footprint | utility_footprint | pump_footprint
    exit_safety: set[tuple[int, int]] = set()
    for point in PORTALS.values():
        exit_safety |= base.circle_cells(point[0], point[1], 4.0)

    fixed_tree_candidates = {
        p for p in land
        if (
            p[0] < 5 or p[0] > MAP_W - 6 or p[1] < 5 or p[1] > MAP_H - 6
            or (p[0] < 25 and p[1] < 22 and base.stable_hash(p[0], p[1], 37) % 5 == 0)
        )
    }
    fixed_blocked = water | path_base | unlockable_path | fixed_footprints | exit_safety | home_safety
    fixed_tree_anchors = base.choose_tree_anchors(fixed_tree_candidates, fixed_blocked, 37, 2, 7)
    fixed_tree_cells = (
        set().union(*(base.footprint_for_tree(x, y) for x, y, _ in fixed_tree_anchors))
        if fixed_tree_anchors else set()
    )

    reserved_zones = {
        "reserved_west_workyard": base.rect_cells(19, 20, 18, 12),
        "reserved_east_orchard": base.rect_cells(88, 16, 20, 13),
        "reserved_south_large_facility": base.rect_cells(73, 66, 23, 14),
        "reserved_greenhouse": base.rect_cells(39, 66, 15, 11),
    }
    reserved_cells = set().union(*reserved_zones.values()) & land
    farmable = land - path_base - unlockable_path - fixed_footprints - fixed_tree_cells - exit_safety - shoreline
    no_build = path_base | unlockable_path | fixed_footprints | fixed_tree_cells | exit_safety | shore_buffer
    buildable_reserved = reserved_cells - no_build
    buildable_free = farmable - no_build - buildable_reserved

    tree_candidates = {
        p for p in farmable
        if p not in home_safety
        and base.stable_hash(p[0], p[1], 61) % 17
        < min(5, 1 + int(math.dist(p, HOME_SPAWN) / 24))
    }
    derelict_tree_anchors = base.choose_tree_anchors(
        tree_candidates,
        water | path_base | fixed_footprints | fixed_tree_cells | exit_safety,
        61,
        2,
        8,
    )

    fishable_water = water - permanent_crossings
    pond_brook_water = fishable_water & (pond | pond_brook)
    south_stream_water = fishable_water - pond_brook_water

    names = (
        "Ground", "Ground_Detail", "Water", "Path", "Hydrology_HighWater_Water",
        "Objects_Back", "Development_Derelict_Back", "Development_Derelict", "Development_Derelict_PathHint",
        "Development_Reclaimed_Back", "Development_Reclaimed", "Development_Expanded_Back",
        "Development_Expanded", "Development_Mature", "Characters",
        "Development_Derelict_Front", "Objects_Front", "Development_Reclaimed_Front",
        "Development_Expanded_Front", "Effects", "Season_Spring", "Season_Summer",
        "Season_Autumn", "Season_Winter", "Anomaly_Light", "Anomaly_Medium",
        "Bridge_Mask", "Crossing_East_Shortcut_Visual", "Crossing_North_Field_Visual",
        "Mask_Crossing_East_Shortcut", "Mask_Crossing_North_Field", "Mask_Hydrology_HighWater",
        "Mask_Hydrology_HighWater_Collision_Add", "Mask_Hydrology_HighWater_Fishable_Add",
        "Mask_Hydrology_HighWater_Farmable_Remove", "Mask_Hydrology_HighWater_Buildable_Remove",
        "Mask_Background_Scenery",
        "Mask_Collision_Water", "Mask_Farmable", "Mask_Buildable_Free",
        "Mask_Buildable_Reserved", "Mask_NoBuild", "Portal_Future_Region_Locked_Visual", "Mask_Crossing_Development_Reclaimed",
        "Mask_Fishing_Ecology_PondBrook", "Mask_Fishing_Ecology_SouthStream",
    )
    grids = {name: grid() for name in names}
    for y in range(MAP_H):
        for x in range(MAP_W):
            grids["Ground"][idx((x, y))] = TERRAIN_FIRST_GID + 160 + base.stable_hash(x, y, 3) % 8
            if (x, y) in land and base.stable_hash(x, y, 5) % 16 == 0:
                grids["Ground_Detail"][idx((x, y))] = OBJECT_FIRST_GID + 128
    for x, y in water:
        grids["Water"][idx((x, y))] = TERRAIN_FIRST_GID + 32 + base.connection_mask(water, x, y)
    for x, y in path_base:
        local = 72 if (x, y) in permanent_crossings else 16 + base.connection_mask(path_base, x, y)
        grids["Path"][idx((x, y))] = TERRAIN_FIRST_GID + local
    for x, y in unlockable_path:
        local = 72 if (x, y) in unlockable_crossings else 16 + base.connection_mask(unlockable_path, x, y)
        grids["Development_Reclaimed"][idx((x, y))] = TERRAIN_FIRST_GID + local

    south_portal_lock_visual_cells = {(x, 94) for x in range(62, 67)}
    for x, y in sorted(south_portal_lock_visual_cells):
        grids["Portal_Future_Region_Locked_Visual"][idx((x, y))] = OBJECT_FIRST_GID + (69 + (x - 62) % 3)

    base.place_tree_components(grids["Objects_Back"], grids["Objects_Front"], fixed_tree_anchors)
    base.place_tree_components(
        grids["Development_Derelict_Back"], grids["Development_Derelict_Front"], derelict_tree_anchors
    )
    base.place_house(grids["Development_Derelict_Back"], grids["Development_Derelict_Front"], "derelict")
    base.place_house(grids["Development_Expanded_Back"], grids["Development_Expanded_Front"], "expanded")
    base.place_arch_region(grids["Objects_Back"], 28, 64, 0, 12, 4, 3)
    base.place_arch_region(grids["Development_Reclaimed_Back"], 91, 39, 5, 12, 3, 3)

    debris_cells: set[tuple[int, int]] = set()
    heavy_debris_cells: set[tuple[int, int]] = set()
    derelict_tree_cells = (
        set().union(*(base.footprint_for_tree(x, y) for x, y, _ in derelict_tree_anchors))
        if derelict_tree_anchors else set()
    )
    for x, y in sorted(farmable):
        if (x, y) in derelict_tree_cells:
            continue
        distance = math.dist((x, y), HOME_SPAWN)
        probability = min(0.34, 0.075 + distance * 0.00255)
        if (base.stable_hash(x, y, 131) % 10000) / 10000.0 >= probability:
            continue
        debris_cells.add((x, y))
        heavy_bias = max(0.035, min(0.31, 0.025 + distance * 0.0030))
        heavy = (base.stable_hash(x, y, 137) % 10000) / 10000.0 < heavy_bias
        if heavy:
            heavy_debris_cells.add((x, y))
            local = (69, 70, 71)[base.stable_hash(x, y, 139) % 3]
        else:
            local = (64, 64, 65, 66, 67, 68)[base.stable_hash(x, y, 149) % 6]
        grids["Development_Derelict"][idx((x, y))] = OBJECT_FIRST_GID + local

    future_path_hint_cells = {
        point
        for point in development_centerlines - water
        if base.stable_hash(point[0], point[1], 173) % 7 >= 2
    }
    for x, y in sorted(future_path_hint_cells):
        grids["Development_Derelict_PathHint"][idx((x, y))] = TERRAIN_FIRST_GID + 16 + base.connection_mask(future_path_hint_cells, x, y)

    built_field_cells = (
        base.rect_cells(40, 38, 13, 9)
        | base.rect_cells(77, 44, 12, 9)
        | base.rect_cells(44, 69, 10, 8)
    ) & farmable
    for x, y in built_field_cells:
        grids["Development_Mature"][idx((x, y))] = TERRAIN_FIRST_GID + (68 if base.stable_hash(x, y, 157) % 3 else 69)
    for p in permanent_crossings:
        grids["Bridge_Mask"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_BRIDGE_PERMANENT
    for p in unlockable_crossings:
        grids["Mask_Crossing_Development_Reclaimed"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_CROSSING_OVERRIDE
    for p in water - permanent_crossings:
        grids["Mask_Collision_Water"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_COLLISION_WATER
    for p in farmable:
        grids["Mask_Farmable"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_FARMABLE
    for p in buildable_free:
        grids["Mask_Buildable_Free"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_BUILDABLE_FREE
    for p in buildable_reserved:
        grids["Mask_Buildable_Reserved"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_BUILDABLE_RESERVED
    for p in no_build:
        grids["Mask_NoBuild"][idx(p)] = LOGIC_FIRST_GID + base.LOGIC_NO_BUILD
    for p in pond_brook_water:
        grids["Mask_Fishing_Ecology_PondBrook"][idx(p)] = LOGIC_FIRST_GID + LOGIC_FISH_ECOLOGY_POND_BROOK
    for p in south_stream_water:
        grids["Mask_Fishing_Ecology_SouthStream"][idx(p)] = LOGIC_FIRST_GID + LOGIC_FISH_ECOLOGY_SOUTH_STREAM

    return {
        "all": all_cells, "water": water, "land": land, "shoreline": shoreline,
        "path_base": path_base, "permanent_crossings": permanent_crossings,
        "unlockable_path": unlockable_path, "unlockable_crossings": unlockable_crossings,
        "high_water_delta": set(), "home_footprint": home_footprint,
        "fixed_footprints": fixed_footprints, "exit_safety": exit_safety,
        "fixed_tree_anchors": fixed_tree_anchors, "fixed_tree_cells": fixed_tree_cells,
        "derelict_tree_anchors": derelict_tree_anchors, "debris_cells": debris_cells,
        "heavy_debris_cells": heavy_debris_cells, "farmable": farmable,
        "buildable_free": buildable_free, "buildable_reserved": buildable_reserved,
        "reserved_zones": reserved_zones, "no_build": no_build,
        "built_field_cells": built_field_cells, "grids": grids,
        "fishable_water": fishable_water,
        "pond_brook_water": pond_brook_water,
        "south_stream_water": south_stream_water,
        "south_portal_lock_visual_cells": south_portal_lock_visual_cells,
        "future_path_hint_cells": future_path_hint_cells,
    }


def add_semantic_objects(root: ET.Element, first_layer_id: int, first_object_id: int) -> tuple[int, int]:
    layer_id, object_id = first_layer_id, first_object_id
    groups: list[ET.Element] = []

    def group(name: str, color: str) -> ET.Element:
        nonlocal layer_id
        item = base.make_object_group(layer_id, name, color)
        layer_id += 1
        groups.append(item)
        return item

    collision = group("Collision", "#ff4040")
    for record in (
        ("boundary_north", 0, 0, 128, 1, "map_boundary"),
        ("boundary_south_west", 0, 95, 62, 1, "map_boundary"),
        ("boundary_south_east", 67, 95, 61, 1, "map_boundary"),
        ("boundary_west_upper", 0, 1, 1, 46, "map_boundary"),
        ("boundary_west_lower", 0, 52, 1, 43, "map_boundary"),
        ("boundary_east_upper", 127, 1, 1, 52, "map_boundary"),
        ("boundary_east_lower", 127, 58, 1, 37, "map_boundary"),
        ("house_footprint", 60, 24, 7, 5, "building_footprint"),
        ("old_utility_footprint", 28, 64, 4, 3, "utility_remnant"),
        ("pond_pump_footprint", 91, 39, 3, 3, "fixed_facility"),
    ):
        name, x, y, w, h, kind = record
        object_id = base.add_rect_object(collision, object_id, name, "collision", x, y, w, h, {"kind": kind})
    object_id = base.add_rect_object(
        collision,
        object_id,
        "boundary_south_future_portal_lock",
        "collision",
        62,
        95,
        5,
        1,
        {
            "kind": "conditional_boundary_lock",
            "stableId": "collision.home.h01.future_region_lock",
            "lockedByDefault": True,
            "unlockCondition": "story.home.h01.future_region_unlocked",
            "operationWhenUnlocked": "remove_collision",
            "lockedVisualLayer": "Portal_Future_Region_Locked_Visual",
            "visualOperationWhenUnlocked": "hide_layer",
        },
    )
    base.set_property(collision, "waterCollisionAuthority", "Mask_Collision_Water")

    farmable = group("Farmable", "#85d45c")
    base.set_property(farmable, "maskLayer", "Mask_Farmable")
    base.set_property(farmable, "boundsOnly", True)
    base.set_property(farmable, "authorityPriority", "mask_over_bounds")
    for name, x, y, w, h in (
        ("farmable_central_meadow", 25, 14, 78, 49),
        ("farmable_west_field", 5, 28, 42, 51),
        ("farmable_south_field", 34, 58, 74, 30),
    ):
        object_id = base.add_rect_object(farmable, object_id, name, "farmable_bounds", x, y, w, h, {"authoritativeMask": "Mask_Farmable", "seasonCropProfile": "h01_open_meadow", "boundsOnly": True})

    buildable = group("Buildable_Free", "#4fc3f7")
    base.set_property(buildable, "maskLayer", "Mask_Buildable_Free")
    base.set_property(buildable, "boundsOnly", True)
    base.set_property(buildable, "authorityPriority", "mask_over_bounds")
    for name, x, y, w, h in (
        ("buildable_central_meadow", 27, 16, 56, 43),
        ("buildable_west_field", 7, 30, 37, 46),
        ("buildable_south_field", 36, 60, 70, 26),
    ):
        object_id = base.add_rect_object(buildable, object_id, name, "buildable_free_bounds", x, y, w, h, {"authoritativeMask": "Mask_Buildable_Free", "boundsOnly": True})

    reserved = group("Buildable_Reserved", "#ffd166")
    for name, x, y, w, h, options in (
        ("reserved_west_workyard", 19, 20, 18, 12, "workyard_or_small_barn"),
        ("reserved_east_orchard", 88, 16, 20, 13, "orchard_or_leisure_garden"),
        ("reserved_south_large_facility", 73, 66, 23, 14, "barn_or_large_production"),
        ("reserved_greenhouse", 39, 66, 15, 11, "greenhouse_or_workshop"),
    ):
        object_id = base.add_rect_object(reserved, object_id, name, "buildable_reserved", x, y, w, h, {"plotId": f"home.h01.plot.{name.removeprefix('reserved_')}", "facilityOptions": options, "authoritativeMask": "Mask_Buildable_Reserved", "boundsOnly": True})
    base.set_property(reserved, "maskLayer", "Mask_Buildable_Reserved")
    base.set_property(reserved, "boundsOnly", True)
    base.set_property(reserved, "authorityPriority", "mask_over_bounds")

    no_build = group("NoBuild", "#ef476f")
    base.set_property(no_build, "maskLayer", "Mask_NoBuild")
    base.set_property(no_build, "boundsOnly", True)
    base.set_property(no_build, "authorityPriority", "mask_over_bounds")
    for name, x, y, w, h, reason in (
        ("nobuild_house", 57, 21, 13, 14, "fixed_home_and_safe_approach"),
        ("nobuild_west_portal", 0, 45, 8, 9, "portal_safety"),
        ("nobuild_east_portal", 120, 51, 8, 9, "portal_safety"),
        ("nobuild_south_portal", 59, 90, 11, 6, "portal_safety"),
        ("nobuild_pond_utility", 89, 35, 8, 10, "fixed_water_utility"),
    ):
        object_id = base.add_rect_object(no_build, object_id, name, "no_build", x, y, w, h, {"reason": reason, "authoritativeMask": "Mask_NoBuild", "boundsOnly": True})
    base.set_property(no_build, "shoreBufferAuthority", "Mask_NoBuild")

    spawn = group("Spawn", "#06d6a0")
    for name, x, y, spawn_id, facing in (
        ("home_safe_spawn_meadow", 63, 31, "home.h01.safe", "south"),
        ("home_door_outside", 63, 29, "home.h01.door_outside", "south"),
        ("visitor_arrival_west_track", 38, 45, "home.h01.visitor_arrival", "east"),
        ("return_from_village", 3, 49, "home.h01.return_from_village", "east"),
        ("return_from_wilderness", 124, 55, "home.h01.return_from_wilderness", "west"),
        ("return_from_future_region", 64, 92, "home.h01.return_from_future_region", "north"),
    ):
        object_id = base.add_point_object(spawn, object_id, name, "spawn", x, y, {"spawnId": spawn_id, "availableAtStart": True, "facing": facing, "safe": True})

    portal = group("Portal", "#118ab2")
    portal_specs = (
        ("portal_village_west", 0, 47, 2, 5, "home.h01.to_village", "village_large_a_candidate", "village.large_a.to_home_h01", "village.large_a.arrival_from_home_h01", "home.h01.return_from_village", True, "always", ""),
        ("portal_wilderness_east", 126, 53, 2, 5, "home.h01.to_wilderness", "wilderness_resource_region_candidate", "wilderness.resource.to_home_h01", "wilderness.resource.arrival_from_home_h01", "home.h01.return_from_wilderness", True, "always", ""),
        ("portal_future_region_south", 62, 94, 5, 2, "home.h01.to_future_region", "future_region_candidate", "future.region.to_home_h01", "future.region.arrival_from_home_h01", "home.h01.return_from_future_region", False, "story.home.h01.future_region_unlocked", "collision.home.h01.future_region_lock"),
    )
    for name, x, y, w, h, portal_id, target, target_portal_id, arrival_spawn_id, return_spawn_id, available, unlock_condition, lock_id in portal_specs:
        object_id = base.add_rect_object(portal, object_id, name, "portal", x, y, w, h, {"portalId": portal_id, "targetMapId": target, "targetPortalId": target_portal_id, "arrivalSpawnId": arrival_spawn_id, "returnSpawnId": return_spawn_id, "availableAtStart": available, "unlockCondition": unlock_condition, "lockedCollisionId": lock_id, "transitionConsumesGameTime": False})
    base.set_property(portal, "transitionConsumesGameTime", False)

    npc = group("NpcAnchor", "#8338ec")
    for name, x, y, role in (
        ("npc_guest_arrival", 38, 45, "guest_arrival"),
        ("npc_building_consult", 67, 34, "construction_consult"),
        ("npc_leisure_event", 93, 35, "pond_leisure_visit"),
    ):
        object_id = base.add_point_object(npc, object_id, name, "npc_anchor", x, y, {"scheduleRole": role, "roleDeprecatedAlias": role, "travelMode": "walk"})

    interaction = group("Interaction", "#ff9f1c")
    for name, x, y, action in (
        ("home_door", 63, 29, "enter_home"),
        ("build_board", 68, 32, "open_estate_building"),
        ("old_utility_remnant", 30, 66, "inspect_or_restore"),
        ("pond_pump", 92, 41, "inspect_or_restore"),
        ("pond_edge", 92, 43, "water_edge_interaction"),
    ):
        object_id = base.add_point_object(interaction, object_id, name, "interaction", x, y, {"interactionId": f"home.h01.interaction.{name}", "action": action})

    story = group("StoryTrigger", "#e63946")
    for name, x, y, w, h, event_id in (
        ("trigger_first_build_zone", 55, 31, 18, 12, "home.h01.first_build"),
        ("trigger_home_social_visit", 37, 41, 29, 13, "home.h01.social_visit"),
        ("trigger_utility_restore", 24, 60, 13, 12, "home.h01.utility_restore"),
    ):
        object_id = base.add_rect_object(story, object_id, name, "story_trigger", x, y, w, h, {"triggerId": event_id, "eventIdDeprecatedAlias": event_id})

    resources = group("ResourceSpawnZone", "#9b5de5")
    for name, x, y, w, h, profile in (
        ("resource_west_meadow", 7, 56, 32, 24, "meadow_mixed"),
        ("resource_north_meadow", 29, 7, 67, 15, "meadow_light"),
        ("resource_east_meadow", 103, 24, 19, 48, "meadow_mixed"),
        ("resource_south_meadow", 35, 67, 65, 20, "meadow_heavy"),
    ):
        object_id = base.add_rect_object(resources, object_id, name, "resource_spawn_zone", x, y, w, h, {"profile": profile, "developmentState": "derelict"})

    seasonal = group("SeasonalResourceZone", "#00b4d8")
    for name, x, y, w, h, profile in (
        ("seasonal_central_meadow", 28, 15, 55, 44, "h01_meadow_crops_and_forage"),
        ("seasonal_pond", 91, 32, 18, 18, "h01_pond_fish_and_forage"),
        ("seasonal_brook", 82, 51, 26, 35, "h01_brook_fish_and_forage"),
        ("seasonal_west_field", 7, 31, 37, 45, "h01_west_field_resources"),
    ):
        object_id = base.add_rect_object(seasonal, object_id, name, "seasonal_resource_zone", x, y, w, h, {"profile": profile, "seasons": "spring,summer,autumn,winter"})

    ecology = group("FishingEcologyZone", "#3a86ff")
    base.set_property(ecology, "boundsOnly", True)
    base.set_property(ecology, "authorityPriority", "mask_over_bounds")
    base.set_property(ecology, "maskLayers", "Mask_Fishing_Ecology_PondBrook|Mask_Fishing_Ecology_SouthStream")
    base.set_property(ecology, "operation", "set_profile")
    for name, x, y, w, h, ecology_id, mask_layer, profile_prefix in (
        ("fish_ecology_pond_brook", 88, 31, 24, 56, "fish_ecology.h01.pond_brook", "Mask_Fishing_Ecology_PondBrook", "fish_table.h01.pond_brook"),
        ("fish_ecology_south_stream", 0, 80, 128, 16, "fish_ecology.h01.south_stream", "Mask_Fishing_Ecology_SouthStream", "fish_table.h01.south_stream"),
    ):
        object_id = base.add_rect_object(
            ecology,
            object_id,
            name,
            "fishing_ecology_zone",
            x,
            y,
            w,
            h,
            {
                "ecologyZoneId": ecology_id,
                "authoritativeMask": mask_layer,
                "boundsOnly": True,
                "springProfile": f"{profile_prefix}.spring",
                "summerProfile": f"{profile_prefix}.summer",
                "autumnProfile": f"{profile_prefix}.autumn",
                "winterProfile": f"{profile_prefix}.winter",
            },
        )

    fishing = group("FishingAccessQA", "#48cae4")
    for name, x, y, ecology_zone_id in (
        ("qa_pond_west_bank", 92, 43, "fish_ecology.h01.pond_brook"),
        ("qa_pond_south_bank", 101, 48, "fish_ecology.h01.pond_brook"),
        ("qa_brook_mid_bank", 99, 63, "fish_ecology.h01.pond_brook"),
        ("qa_stream_north_bank", 77, 83, "fish_ecology.h01.south_stream"),
    ):
        object_id = base.add_point_object(fishing, object_id, name, "fishing_access_qa", x, y, {"qaOnly": True, "fixedFishingSpot": False, "castRule": "endpoint_hits_fishable_water", "ecologyZoneId": ecology_zone_id})

    occlusion = group("Occlusion", "#577590")
    for name, x, y, w, h, kind in (
        ("occlusion_northwest_treebelt", 0, 0, 26, 18, "tree_canopy"),
        ("occlusion_boundary_trees", 0, 0, 128, 6, "tree_canopy"),
        ("occlusion_house_eave", 60, 24, 7, 2, "roof_eave"),
    ):
        object_id = base.add_rect_object(occlusion, object_id, name, "occlusion", x, y, w, h, {"kind": kind})

    anomaly = group("AnomalyStateAnchor", "#b5179e")
    for name, x, y, role, target, target_x, target_y in (
        ("anomaly_anchor_old_utility", 30, 66, "subtle_repetition", "old_utility_remnant", 30, 66),
        ("anomaly_anchor_pond_reflection", 92, 43, "reflection_delay", "pond_reflection_surface", 100, 39),
        ("anomaly_anchor_home_path", 54, 37, "path_displacement_hint", "home_path_segment", 54, 37),
    ):
        object_id = base.add_point_object(anomaly, object_id, name, "anomaly_state_anchor", x, y, {"stableId": f"home.h01.{name}", "role": role, "target": target, "targetCellX": target_x, "targetCellY": target_y, "waterPlacement": False, "interactive": False, "collisionChange": False, "geometryChange": False, "lightMediumUsesSameGeometry": True})

    for item in groups:
        root.append(item)
    return layer_id, object_id


def build_authoritative(layout: dict[str, Any]) -> Path:
    base.add_semantic_objects = add_semantic_objects
    original = base.build_authoritative_map(BATCH_ROOT, layout)
    tree = ET.parse(original)
    root = tree.getroot()
    for name in (
        "Hydrology_HighWater_Water",
        "Crossing_East_Shortcut_Visual",
        "Crossing_North_Field_Visual",
        "Mask_Crossing_East_Shortcut",
        "Mask_Crossing_North_Field",
        "Mask_Hydrology_HighWater",
        "Mask_Hydrology_HighWater_Collision_Add",
        "Mask_Hydrology_HighWater_Fishable_Add",
        "Mask_Hydrology_HighWater_Farmable_Remove",
        "Mask_Hydrology_HighWater_Buildable_Remove",
        "Mask_Background_Scenery",
    ):
        layer = root.find(f"layer[@name='{name}']")
        if layer is not None:
            root.remove(layer)
    replacements = {
        "estateTypeId": "H01",
        "displayNameZh": "开阔草甸",
        "stateCompositionMode": "orthogonal_season_development_anomaly",
        "seasonProfile": "runtime_selected_pending_h01_art_pass",
        "anomalyProfile": "runtime_selected_pending_h01_art_pass",
        "layoutStatus": "independent_review_feedback_addressed_pending_user_layout_approval",
        "sourceConceptRole": "late_game_build_potential_reference_only",
        "developmentStateComposition": "cumulative",
        "developmentStateOrder": "derelict,reclaimed,expanded,mature",
        "semanticMaskAuthority": "tile_masks_override_bounds_objects",
        "fishEcologyAuthority": "Mask_Fishing_Ecology_PondBrook+Mask_Fishing_Ecology_SouthStream",
    }
    props = root.find("properties")
    if props is not None:
        for prop in list(props):
            if prop.attrib.get("name") == "hydrologyProfile":
                props.remove(prop)
    for key, value in replacements.items():
        base.set_property(root, key, value)
    for ts in root.findall("tileset"):
        ts.attrib["source"] = ts.attrib["source"].replace("h02_layout_", "h01_layout_")

    for layer in root.findall("layer"):
        props = layer.find("properties")
        state_prop = props.find("property[@name='state']") if props is not None else None
        if state_prop is not None:
            state_value = state_prop.attrib.get("value", state_prop.text or "")
            props.remove(state_prop)
            base.set_property(layer, "stateValue", state_value)
        name = layer.attrib.get("name", "")
        if name.startswith("Development_Derelict"):
            base.set_property(layer, "activationRule", "exact_state")
        elif name.startswith("Development_Reclaimed"):
            base.set_property(layer, "activationRule", "at_or_above_reclaimed")
        elif name.startswith("Development_Expanded"):
            base.set_property(layer, "activationRule", "at_or_above_expanded")
        elif name == "Development_Mature":
            base.set_property(layer, "activationRule", "at_or_above_mature")
        if name == "Development_Derelict":
            base.set_property(layer, "persistence", "per_cell_stable_seed")
            base.set_property(layer, "clearRule", "persist_removed_resource_by_cell_and_stable_resource_id")

    next_layer_id = int(root.attrib.get("nextlayerid", "1"))
    additional_layers = (
        (
            "Development_Derelict_PathHint",
            layout["grids"]["Development_Derelict_PathHint"],
            True,
            None,
            {
                "role": "broken_future_route_readability_hint",
                "stateAxis": "development",
                "stateValue": "derelict",
                "activationRule": "exact_state",
                "authority": "visual_only_no_gameplay_permission",
            },
        ),
        (
            "Portal_Future_Region_Locked_Visual",
            layout["grids"]["Portal_Future_Region_Locked_Visual"],
            True,
            None,
            {
                "role": "conditional_portal_lock_visual",
                "stateAxis": "story",
                "stateValue": "locked",
                "stableLockId": "collision.home.h01.future_region_lock",
                "unlockCondition": "story.home.h01.future_region_unlocked",
                "operation": "hide_when_unlocked",
            },
        ),
        (
            "Mask_Crossing_Development_Reclaimed",
            layout["grids"]["Mask_Crossing_Development_Reclaimed"],
            False,
            0.5,
            {
                "authority": "development_crossing_override",
                "stateAxis": "development",
                "stateValue": "reclaimed",
                "activationRule": "at_or_above_reclaimed",
                "operation": "remove_water_collision_fishable_and_ecology_when_active",
                "stableCrossingId": "crossing.home.h01.reclaimed_east_brook",
                "ecologyMasksAffected": "Mask_Fishing_Ecology_PondBrook|Mask_Fishing_Ecology_SouthStream",
            },
        ),
        (
            "Mask_Fishing_Ecology_PondBrook",
            layout["grids"]["Mask_Fishing_Ecology_PondBrook"],
            False,
            0.5,
            {"authority": "fishing_ecology", "ecologyZoneId": "fish_ecology.h01.pond_brook", "operation": "set_profile"},
        ),
        (
            "Mask_Fishing_Ecology_SouthStream",
            layout["grids"]["Mask_Fishing_Ecology_SouthStream"],
            False,
            0.5,
            {"authority": "fishing_ecology", "ecologyZoneId": "fish_ecology.h01.south_stream", "operation": "set_profile"},
        ),
    )
    for name, values, visible, opacity, properties in additional_layers:
        layer = base.make_tile_layer(next_layer_id, name, values, visible, opacity, properties)
        if name == "Development_Derelict_PathHint":
            objects_back = root.find("layer[@name='Objects_Back']")
            insertion_index = list(root).index(objects_back) if objects_back is not None else len(root)
        else:
            insertion_index = next((index for index, child in enumerate(list(root)) if child.tag == "objectgroup"), len(root))
        root.insert(insertion_index, layer)
        next_layer_id += 1
    root.attrib["nextlayerid"] = str(next_layer_id)
    ET.indent(tree, space="  ")
    output = BATCH_ROOT / "source/h01_open_meadow_authoritative.tmx"
    tree.write(output, encoding="utf-8", xml_declaration=True)
    original.unlink()
    return output


def configure_development(root: ET.Element, state: str) -> None:
    order = {"derelict": 0, "reclaimed": 1, "expanded": 2, "mature": 3}
    active_level = order[state]
    for layer in root.findall("layer"):
        name = layer.attrib.get("name", "")
        visible = None
        if name.startswith("Development_Derelict"):
            visible = state == "derelict"
        elif name.startswith("Development_Reclaimed"):
            visible = active_level >= order["reclaimed"]
        elif name.startswith("Development_Expanded"):
            visible = active_level >= order["expanded"]
        elif name == "Development_Mature":
            visible = active_level >= order["mature"]
        if visible is not None:
            base.set_visible(layer, visible)


def build_reviews(authoritative: Path, layout: dict[str, Any]) -> dict[str, Path]:
    output_root = BATCH_ROOT / "derived-preview"
    output_root.mkdir(parents=True, exist_ok=True)
    outputs: dict[str, Path] = {}
    for key, state in (("spring_derelict_normal", "derelict"), ("spring_built_normal", "mature")):
        tree = ET.parse(authoritative)
        root = tree.getroot()
        base.set_property(root, "authoritativeSource", False)
        base.set_property(root, "derivedPreviewOnly", True)
        base.set_property(root, "reviewDevelopment", state)
        base.set_property(root, "reviewDevelopmentComposition", "cumulative")
        base.set_property(root, "reviewSeason", "spring")
        base.set_property(root, "reviewAnomaly", "normal")
        configure_development(root, state)
        if state == "derelict":
            collision_cells = layout["water"] - layout["permanent_crossings"]
        else:
            collision_cells = layout["water"] - layout["permanent_crossings"] - layout["unlockable_crossings"]
        collision_values = grid()
        for point in collision_cells:
            collision_values[idx(point)] = LOGIC_FIRST_GID + base.LOGIC_COLLISION_WATER
        base.write_grid_replace(base.layer_by_name(root, "Mask_Collision_Water"), collision_values)
        if state != "derelict":
            for layer_name, source_cells, logic_id in (
                (
                    "Mask_Fishing_Ecology_PondBrook",
                    layout["pond_brook_water"] - layout["unlockable_crossings"],
                    LOGIC_FISH_ECOLOGY_POND_BROOK,
                ),
                (
                    "Mask_Fishing_Ecology_SouthStream",
                    layout["south_stream_water"] - layout["unlockable_crossings"],
                    LOGIC_FISH_ECOLOGY_SOUTH_STREAM,
                ),
            ):
                ecology_values = grid()
                for point in source_cells:
                    ecology_values[idx(point)] = LOGIC_FIRST_GID + logic_id
                base.write_grid_replace(base.layer_by_name(root, layer_name), ecology_values)
        for ts in root.findall("tileset"):
            ts.attrib["source"] = "../source/" + ts.attrib["source"]
        output = output_root / f"h01_review_{key}.tmx"
        ET.indent(tree, space="  ")
        tree.write(output, encoding="utf-8", xml_declaration=True)
        outputs[key] = output
    return outputs


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=size)


def make_review_boards(rendered: dict[str, Path], font_path: Path) -> None:
    previews = BATCH_ROOT / "previews"
    derelict = Image.open(rendered["spring_derelict_normal"]).convert("RGB")
    built = Image.open(rendered["spring_built_normal"]).convert("RGB")
    map_size = (1640, round(1640 * MAP_H / MAP_W))
    map_image = derelict.resize(map_size, Image.Resampling.NEAREST)
    board = Image.new("RGB", (2400, 1320), (27, 36, 38))
    board.paste(map_image, (40, 110))
    overlay = ImageDraw.Draw(board, "RGBA")
    overlay.text((40, 25), "H01 开阔草甸｜技术布局候选 v1", font=font(font_path, 46), fill=(238, 242, 229, 255))
    sx, sy = map_size[0] / MAP_W, map_size[1] / MAP_H
    def point(x: float, y: float) -> tuple[int, int]:
        return round(40 + x * sx), round(110 + y * sy)
    for label, x, y, w, h, color in (
        ("中央开阔草甸", 25, 14, 61, 48, (85, 178, 117, 86)),
        ("西侧自由建设区", 5, 28, 40, 51, (200, 169, 86, 86)),
        ("南部大设施容量", 34, 58, 73, 30, (182, 121, 91, 86)),
        ("池塘与曲溪", 88, 31, 23, 55, (74, 174, 205, 90)),
    ):
        a, z = point(x, y), point(x + w, y + h)
        overlay.rounded_rectangle((*a, *z), radius=10, fill=color, outline=color[:3] + (220,), width=3)
        overlay.text((a[0] + 10, a[1] + 9), label, font=font(font_path, 21), fill=(245, 247, 238, 255))
    for label, x, y, color in (
        ("西出口：大型村庄", 1, 49, (70, 190, 220, 255)),
        ("东出口：野外地区", 112, 55, (70, 190, 220, 255)),
        ("条件出口", 64, 91, (214, 100, 120, 255)),
        ("主屋与安全出生点", 63, 31, (240, 184, 74, 255)),
        ("旧公共设施", 30, 66, (214, 150, 90, 255)),
    ):
        p = point(x, y)
        overlay.ellipse((p[0]-7, p[1]-7, p[0]+7, p[1]+7), fill=color)
        overlay.text((p[0]+10, p[1]-14), label, font=font(font_path, 19), fill=(244, 246, 238, 255), stroke_width=3, stroke_fill=(16, 24, 27, 240))
    panel_x = 1730
    overlay.rounded_rectangle((panel_x, 110, 2360, 1255), radius=18, fill=(16, 25, 28, 244), outline=(93, 124, 119, 255), width=2)
    overlay.text((panel_x+30, 145), "本轮关键修正", font=font(font_path, 27), fill=(240, 220, 149, 255))
    notes = (
        "• 概念图只作建成后潜力参考",
        "• 默认是荒废住宅与随机杂物",
        "• 主屋附近仅连续概率减轻负担",
        "• 无冲突空地统一进入可耕掩码",
        "• 自由建造与固定设施预留并存",
        "• 两个普通出口开局即可到达",
        "• 池塘、曲溪和边界溪连续可钓",
        "• 四季与轻/中异常保留同图钩子",
    )
    y = 205
    for note in notes:
        overlay.text((panel_x+30, y), note, font=font(font_path, 21), fill=(219, 229, 216, 255))
        y += 54
    overlay.text((panel_x+30, 1180), "候选未接入 Godot｜shippingApproval=false", font=font(font_path, 20), fill=(179, 194, 187, 255))
    board.save(previews / "h01_layout_annotated_cn_2400x1320.png")

    size = (1120, round(1120 * MAP_H / MAP_W))
    compare = Image.new("RGB", (2400, size[1] + 190), (27, 36, 38))
    compare.paste(derelict.resize(size, Image.Resampling.NEAREST), (50, 130))
    compare.paste(built.resize(size, Image.Resampling.NEAREST), (1230, 130))
    draw = ImageDraw.Draw(compare)
    draw.text((50, 25), "H01 开局荒废状态 / 建设后容量示意", font=font(font_path, 44), fill=(238, 242, 229))
    draw.text((50, 82), "开局：杂草、树木与石块连续随机覆盖", font=font(font_path, 29), fill=(228, 197, 130))
    draw.text((1230, 82), "建设后：仅示意田地、支路和设施容量", font=font(font_path, 29), fill=(125, 211, 183))
    compare.save(previews / "h01_derelict_built_compare_cn_2400x1030.png")


def render_reviews(reviews: dict[str, Path], tiled: Path, font_path: Path) -> dict[str, Path]:
    previews = BATCH_ROOT / "previews"
    previews.mkdir(parents=True, exist_ok=True)
    rendered: dict[str, Path] = {}
    for key, tmx in reviews.items():
        full = previews / f"h01_review_{key}_4096x3072.png"
        result = subprocess.run([str(tiled), str(tmx), str(full)], capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise RuntimeError(result.stderr or result.stdout)
        rendered[key] = full
        image = Image.open(full).convert("RGBA")
        image.resize((1280, 960), Image.Resampling.NEAREST).save(previews / f"h01_review_{key}_1280x960.png")
        for name, center in (("home", (63, 28)), ("pond", (98, 41)), ("west_field", (27, 55)), ("future_route", (48, 61)), ("south_field", (64, 72)), ("south_portal", (64, 92))):
            base.crop_viewport(image, center).save(previews / f"h01_review_{key}_{name}_640x360.png")
    make_review_boards(rendered, font_path)
    return rendered


def write_records(authoritative: Path, layout: dict[str, Any], font_path: Path) -> list[Path]:
    root = ET.parse(authoritative).getroot()
    layers = []
    for layer in root.findall("layer"):
        values = base.parse_grid(layer)
        layers.append({"name": layer.attrib["name"], "visibleByDefault": layer.attrib.get("visible", "1") != "0", "nonzeroCells": sum(v != 0 for v in values), "properties": base.xml_properties(layer)})
    groups = []
    for item in root.findall("objectgroup"):
        groups.append({"name": item.attrib["name"], "objects": [base.object_record(obj) for obj in item.findall("object")], "properties": base.xml_properties(item)})
    manifest = {
        "schemaVersion": 1, "batchId": BATCH_ID, "mapId": MAP_ID,
        "estateTypeId": "H01", "displayNameZh": "开阔草甸", "status": STATUS,
        "mapSize": {"widthTiles": MAP_W, "heightTiles": MAP_H, "tileWidthPixels": TILE, "tileHeightPixels": TILE, "pixelWidth": MAP_W*TILE, "pixelHeight": MAP_H*TILE},
        "authoritativeTmx": str(authoritative.resolve()),
        "tilesets": [{"firstGid": int(ts.attrib["firstgid"]), "source": ts.attrib["source"]} for ts in root.findall("tileset")],
        "layers": layers, "objectGroups": groups,
        "functionalCounts": {
            "waterCells": len(layout["water"]), "permanentCrossingCells": len(layout["permanent_crossings"]),
            "developmentCrossingCells": len(layout["unlockable_crossings"]),
            "fishableWaterCells": len(layout["fishable_water"]),
            "pondBrookEcologyCells": len(layout["pond_brook_water"]),
            "southStreamEcologyCells": len(layout["south_stream_water"]),
            "farmableCells": len(layout["farmable"]), "buildableFreeCells": len(layout["buildable_free"]),
            "buildableReservedCells": len(layout["buildable_reserved"]), "noBuildCells": len(layout["no_build"]),
            "derelictDebrisCells": len(layout["debris_cells"]), "heavyDebrisCells": len(layout["heavy_debris_cells"]),
            "fixedTreeAnchors": len(layout["fixed_tree_anchors"]), "derelictTreeAnchors": len(layout["derelict_tree_anchors"]),
            "futurePathHintCells": len(layout["future_path_hint_cells"]),
            "southPortalLockVisualCells": len(layout["south_portal_lock_visual_cells"]),
        },
        "stateAxes": {"development": ["derelict", "reclaimed", "expanded", "mature"], "season": ["spring", "summer", "autumn", "winter"], "anomaly": ["normal", "light", "medium"], "construction": ["fixed", "free", "reserved"]},
        "fishing": {"rule": "any_walkable_origin_if_cast_endpoint_hits_fishable_water", "fixedFishingSpots": False, "bridgeCellsFishable": False, "qaPointsOnly": True, "ecologyCoverage": "all fishable cells have exactly one stable ecology zone", "seasons": ["spring", "summer", "autumn", "winter"]},
        "semanticAuthority": {"functionalMasksOverrideBoundsObjects": True, "pointPlacement": "tmx_cell_origin_to_godot_cell_center", "developmentComposition": "cumulative"},
        "independentReview": "postfix_audit_passed_no_must_or_should",
        "outstandingBeforeRuntime": ["User layout approval", "H01-specific meadow vegetation/wind-grass/wildflower/shore-detail and four-season art", "H01 anomaly overlays", "Godot importer/runtime wiring", "Commercial shipping authorization"],
        "runtimeIntegrated": False, "shippingApproval": False,
    }
    manifest_path = BATCH_ROOT / "H01_LAYOUT_MAP_MANIFEST.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    concept = REPO_ROOT / "art-source/maps/concept-batch-001/H01_open_meadow.png"
    approval = REPO_ROOT / "art-source/maps/h03-forest-hollow/formal-tiles/H03_PIPELINE_BENCHMARK_APPROVAL.json"
    resources = []
    for path in sorted((BATCH_ROOT / "source/tilesets").iterdir()):
        record: dict[str, Any] = {"path": str(path.resolve()), "format": path.suffix[1:].upper(), "bytes": path.stat().st_size, "sha256": sha256(path)}
        if path.suffix.lower() == ".png":
            with Image.open(path) as image:
                record["dimensionsPixels"] = f"{image.width}x{image.height}"
                record["mode"] = image.mode
        resources.append(record)
    asset = {
        "schemaVersion": 1, "batchId": BATCH_ID, "mapId": MAP_ID, "status": STATUS, "createdAt": "2026-07-23",
        "sourceAndAuthorization": {
            "conceptReference": {"path": str(concept.resolve()), "source": "OpenAI built-in image generation from concept-batch-001", "use": "late-game capacity and open-meadow direction only", "pixelsCopiedIntoRuntimeAtlases": False, "shippingApproval": False},
            "styleDonor": {"approvalRecord": str(approval.resolve()), "source": "Project-owned H03 Batch 007 deterministic native-32px candidate atlases", "use": "temporary shared estate visual language", "thirdPartyOrCommercialGamePixels": False, "shippingApproval": False},
            "layoutSpecificWork": {"source": "Deterministic Python/Tiled generation in this batch", "thirdPartyOrAiReferencePixelsCopied": False, "authorization": "project-internal candidate production only"},
            "reviewLabels": {"fontReadFrom": str(font_path), "fontCopiedIntoProject": False, "runtimeResource": False},
        },
        "generatedResources": resources, "runtimeIntegrated": False, "shippingApproval": False,
    }
    asset_path = BATCH_ROOT / "H01_LAYOUT_ASSET_RECORD.json"
    asset_path.write_text(json.dumps(asset, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    handoff = {
        "schemaVersion": 1,
        "handoffId": "h01_open_meadow_godot_import_handoff_v1",
        "mapId": MAP_ID,
        "status": "tiled_layout_candidate_ready_for_project_owned_conversion",
        "authoritativeTmx": str(authoritative.resolve()),
        "dispositionContract": str((REPO_ROOT / "art-source/maps/estate-pipeline-v1/TILED_TO_GODOT_DISPOSITION_V1.json").resolve()),
        "logicTileset": str((BATCH_ROOT / "source/tilesets/h01_layout_logic.tsx").resolve()),
        "coordinateConversion": {"pointSource": "tile_cell_origin", "godotTarget": "cell_center", "formula": "Vector2(cell_x * 32 + 16, cell_y * 32 + 16)"},
        "functionalAuthority": {"farmable": "Mask_Farmable", "buildableFree": "Mask_Buildable_Free", "buildableReserved": "Mask_Buildable_Reserved", "noBuild": "Mask_NoBuild", "boundsObjects": "description_and_QA_only"},
        "development": {
            "composition": "cumulative",
            "order": ["derelict", "reclaimed", "expanded", "mature"],
            "crossingMask": "Mask_Crossing_Development_Reclaimed",
            "crossingOperation": "remove_water_collision_fishable_and_ecology_when_active",
            "crossingActivation": "at_or_above_reclaimed",
        },
        "fishing": {
            "continuousCastRule": True,
            "ecologyMasks": ["Mask_Fishing_Ecology_PondBrook", "Mask_Fishing_Ecology_SouthStream"],
            "fourSeasonProfileIdsRecorded": True,
            "crossingStateRemovalPrecedence": "active crossing removes collision, fishable eligibility and ecology profile after base ecology assignment",
        },
        "conditionalPortal": {
            "portalId": "home.h01.to_future_region",
            "lockedCollisionId": "collision.home.h01.future_region_lock",
            "lockedVisualLayer": "Portal_Future_Region_Locked_Visual",
            "unlockCondition": "story.home.h01.future_region_unlocked",
            "transitionConsumesGameTime": False,
        },
        "artReadiness": {"springDerelictLayout": "complete_candidate", "summerAutumnWinter": "hook_only_art_pending", "lightMediumAnomaly": "hook_only_art_pending", "h01SpecificMeadowArt": "wind_grass_wildflower_shore_detail_pending_formal_art_batch"},
        "runtimeConversion": {"officialTiledObjectExportAuthoritative": False, "semanticPostprocessorRequired": True, "godot471FixtureValidated": False, "runtimeIntegrated": False},
        "shippingApproval": False,
    }
    handoff_path = BATCH_ROOT / "H01_GODOT_IMPORT_HANDOFF.json"
    handoff_path.write_text(json.dumps(handoff, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    design_path = BATCH_ROOT / "H01_LAYOUT_DESIGN_RECORD.md"
    design_path.write_text(f"""# H01 开阔草甸 Batch 001 技术布局记录

## 对概念图的处理

概念图被明确视作中后期建设潜力参考，不作为开局布局。保留的是开阔视野、低地形阻力和高自由建造容量；大宅、围墙、成片田地、密集工坊与景观设施全部移出默认荒废状态。

## 技术量化

- 地图：{MAP_W}×{MAP_H} 格，32×32 px，总像素 {MAP_W*TILE}×{MAP_H*TILE}。
- 水域：{len(layout['water'])} 格；可耕：{len(layout['farmable'])} 格。
- 自由建造：{len(layout['buildable_free'])} 格；设施预留：{len(layout['buildable_reserved'])} 格。
- 开局杂物：{len(layout['debris_cells'])} 格，其中重型 {len(layout['heavy_debris_cells'])} 格。
- 两个普通出口开局可达；南侧条件出口只受剧情条件限制。

## 设计取舍

- 主屋放在中央偏北；第一屏先读到开阔草地和东西主路，池塘与曲溪在向东探索后进入视野，不宣称首屏直接看到水景。
- 水面采用池塘—曲溪—南界溪的连续网络，所有可钓水面统一使用投竿终点判定，不设固定钓点。
- 荒废度以离住宅距离连续增加的概率生成，不制造矩形新手净地。
- 混合建造保留大面积自由区，同时为工坊、果园、大型畜舍和温室留出稳定设施位。
- 四季与轻/中异常沿用同一几何，只在权威 TMX 中预留替换层和状态锚点。
- 开局的后期支路用稀疏旧路痕提示“此处并非普通可耕草地”；南侧条件出口以五格石障视觉层对应同 stable lock，解锁时碰撞与视觉一起移除。
- H01 专属风草、野花和水岸细节留在正式草甸美术批次完成；当前仍是技术布局，不借用 H03 像素冒充最终地域美术。
""", encoding="utf-8")

    delivery_path = BATCH_ROOT / "H01_LAYOUT_DELIVERY.md"
    delivery_path.write_text(f"""# H01 开阔草甸 Batch 001 交付说明

- 地图 ID：`{MAP_ID}`
- 地图尺寸：{MAP_W}×{MAP_H} tiles；32×32 px；{MAP_W*TILE}×{MAP_H*TILE} px
- 权威源：`{authoritative.resolve()}`
- 默认状态：开局荒废；建设后 TMX 仅为可重建审阅派生物。
- 技术状态：`layout-only`；春季荒废布局已完整，夏/秋/冬与轻/中异常均为 `hook_only_art_pending`，不是 runtime-ready。
- Godot 转换交接：`{(BATCH_ROOT / 'H01_GODOT_IMPORT_HANDOFF.json').resolve()}`
- 自动验证：`{(BATCH_ROOT / 'H01_LAYOUT_VALIDATION.json').resolve()}`（构建成功要求全部检查通过）。
- 来源与授权：见 `H01_LAYOUT_ASSET_RECORD.json`；概念图像素未进入地图图集。
- Tiled：由 D 盘安装的 `tmxrasterizer.exe` 实际解析和栅格化。
- 尚未接入：Godot、正式场景、运行时季节/异常/发展状态切换。
- 未修改：`project.godot`、核心代码、存档 Schema、Git 历史。
- `runtimeIntegrated=false`；`shippingApproval=false`。
""", encoding="utf-8")
    return [manifest_path, asset_path, handoff_path, design_path, delivery_path]


def bfs(start: tuple[int, int], walkable: set[tuple[int, int]]) -> set[tuple[int, int]]:
    reached = {start}
    queue: deque[tuple[int, int]] = deque([start])
    while queue:
        point = queue.popleft()
        for neighbor in base.neighbors4(point):
            if neighbor in walkable and neighbor not in reached:
                reached.add(neighbor)
                queue.append(neighbor)
    return reached


def validate(authoritative: Path, reviews: dict[str, Path], rendered: dict[str, Path], layout: dict[str, Any]) -> Path:
    checks: list[dict[str, Any]] = []
    def check(name: str, passed: bool, evidence: Any) -> None:
        checks.append({"name": name, "passed": bool(passed), "evidence": str(evidence)})

    tree = ET.parse(authoritative)
    root = tree.getroot()
    check("map_dimensions", root.attrib.get("width") == "128" and root.attrib.get("height") == "96", f"{root.attrib.get('width')}x{root.attrib.get('height')}")
    check("tile_dimensions", root.attrib.get("tilewidth") == "32" and root.attrib.get("tileheight") == "32", "32x32")
    check("authoritative_flag", base.xml_properties(root).get("authoritativeSource") is True, base.xml_properties(root).get("authoritativeSource"))
    check("default_derelict", root.find("layer[@name='Development_Derelict']") is not None and root.find("layer[@name='Development_Derelict']").attrib.get("visible", "1") != "0", "visible")
    check("shipping_false", base.xml_properties(root).get("shippingApproval") is False, base.xml_properties(root).get("shippingApproval"))
    check("runtime_false", base.xml_properties(root).get("runtimeIntegrated") is False, base.xml_properties(root).get("runtimeIntegrated"))
    layer_names = {layer.attrib["name"] for layer in root.findall("layer")}
    object_names = {layer.attrib["name"] for layer in root.findall("objectgroup")}
    for name in H01_REQUIRED_LAYERS:
        check(f"required_layer:{name}", name in layer_names, name)
    for name in H01_REQUIRED_OBJECT_GROUPS:
        check(f"required_object_layer:{name}", name in object_names, name)
    for layer in root.findall("layer"):
        check(f"grid_size:{layer.attrib['name']}", len(base.parse_grid(layer)) == CELL_COUNT, len(base.parse_grid(layer)))
    check("water_reasonable", 350 < len(layout["water"]) < 1800, len(layout["water"]))
    check("farmable_capacity", len(layout["farmable"]) > 8000, len(layout["farmable"]))
    check("free_build_capacity", len(layout["buildable_free"]) > 6000, len(layout["buildable_free"]))
    check("reserved_capacity", len(layout["buildable_reserved"]) > 500, len(layout["buildable_reserved"]))
    check("farmable_no_water", not (layout["farmable"] & layout["water"]), len(layout["farmable"] & layout["water"]))
    check("farmable_no_path", not (layout["farmable"] & layout["path_base"]), len(layout["farmable"] & layout["path_base"]))
    check("farmable_reserves_future_path", not (layout["farmable"] & layout["unlockable_path"]), len(layout["farmable"] & layout["unlockable_path"]))
    check("free_build_reserves_future_path", not (layout["buildable_free"] & layout["unlockable_path"]), len(layout["buildable_free"] & layout["unlockable_path"]))
    check("reserved_build_reserves_future_path", not (layout["buildable_reserved"] & layout["unlockable_path"]), len(layout["buildable_reserved"] & layout["unlockable_path"]))
    check("buildable_free_subset", layout["buildable_free"] <= layout["farmable"], len(layout["buildable_free"] - layout["farmable"]))
    check("buildable_reserved_subset", layout["buildable_reserved"] <= layout["farmable"], len(layout["buildable_reserved"] - layout["farmable"]))
    check("crossings_in_water", layout["permanent_crossings"] <= layout["water"], len(layout["permanent_crossings"] - layout["water"]))
    check("development_crossings_in_water", layout["unlockable_crossings"] <= layout["water"], len(layout["unlockable_crossings"] - layout["water"]))
    check("development_crossings_present", len(layout["unlockable_crossings"]) > 0, len(layout["unlockable_crossings"]))
    water_components = base.connected_components(layout["water"])
    check("fishable_water_is_continuous", len(water_components) == 1, [len(component) for component in water_components])
    water_collision = layout["water"] - layout["permanent_crossings"]
    walkable = layout["all"] - water_collision - layout["fixed_footprints"] - layout["fixed_tree_cells"]
    reached = bfs(HOME_SPAWN, walkable)
    check("spawn_walkable", HOME_SPAWN in walkable, HOME_SPAWN)
    check("west_exit_reachable", PORTALS["portal_village_west"] in reached, PORTALS["portal_village_west"])
    check("east_exit_reachable", PORTALS["portal_wilderness_east"] in reached, PORTALS["portal_wilderness_east"])

    expected_boundary = (
        {(x, 0) for x in range(MAP_W)}
        | {(x, MAP_H - 1) for x in range(MAP_W)}
        | {(0, y) for y in range(1, MAP_H - 1) if not 47 <= y <= 51}
        | {(MAP_W - 1, y) for y in range(1, MAP_H - 1) if not 53 <= y <= 57}
    )
    actual_boundary: set[tuple[int, int]] = set()
    collision_group = root.find("objectgroup[@name='Collision']")
    if collision_group is not None:
        for obj in collision_group.findall("object"):
            if base.xml_properties(obj).get("kind") not in {"map_boundary", "conditional_boundary_lock"}:
                continue
            x = round(float(obj.attrib.get("x", "0")) / TILE)
            y = round(float(obj.attrib.get("y", "0")) / TILE)
            width = round(float(obj.attrib.get("width", "0")) / TILE)
            height = round(float(obj.attrib.get("height", "0")) / TILE)
            actual_boundary |= base.rect_cells(x, y, width, height)
    check("boundary_blocks_all_nonportal_edges_and_locked_south", actual_boundary == expected_boundary, f"missing={len(expected_boundary-actual_boundary)},extra={len(actual_boundary-expected_boundary)}")

    south_lock = collision_group.find("object[@name='boundary_south_future_portal_lock']") if collision_group is not None else None
    south_lock_props = base.xml_properties(south_lock) if south_lock is not None else {}
    check("south_portal_locked_by_default", south_lock_props.get("lockedByDefault") is True and bool(south_lock_props.get("unlockCondition")) and south_lock_props.get("lockedVisualLayer") == "Portal_Future_Region_Locked_Visual" and south_lock_props.get("visualOperationWhenUnlocked") == "hide_layer", south_lock_props)

    locked_visual_layer = base.layer_by_name(root, "Portal_Future_Region_Locked_Visual")
    locked_visual_props = base.xml_properties(locked_visual_layer)
    locked_visual_cells = {
        (index % MAP_W, index // MAP_W)
        for index, value in enumerate(base.parse_grid(locked_visual_layer))
        if value
    }
    check("south_portal_lock_visual_exact", locked_visual_cells == layout["south_portal_lock_visual_cells"], len(locked_visual_cells ^ layout["south_portal_lock_visual_cells"]))
    check("south_portal_lock_visual_contract", locked_visual_layer.attrib.get("visible", "1") != "0" and locked_visual_props.get("stableLockId") == south_lock_props.get("stableId") and locked_visual_props.get("unlockCondition") == south_lock_props.get("unlockCondition") and locked_visual_props.get("operation") == "hide_when_unlocked", locked_visual_props)

    portal_group = root.find("objectgroup[@name='Portal']")
    portal_objects = portal_group.findall("object") if portal_group is not None else []
    for portal_obj in portal_objects:
        props = base.xml_properties(portal_obj)
        check(f"portal_stable_contract:{portal_obj.attrib.get('name')}", bool(props.get("portalId")) and bool(props.get("targetPortalId")) and bool(props.get("arrivalSpawnId")) and bool(props.get("returnSpawnId")) and bool(props.get("unlockCondition")), props)
    spawn_ids = {
        base.xml_properties(obj).get("spawnId")
        for obj in root.findall("objectgroup[@name='Spawn']/object")
    }
    for expected_spawn in ("home.h01.return_from_village", "home.h01.return_from_wilderness", "home.h01.return_from_future_region"):
        check(f"return_spawn:{expected_spawn}", expected_spawn in spawn_ids, sorted(str(item) for item in spawn_ids))
    for spawn_obj in root.findall("objectgroup[@name='Spawn']/object"):
        spawn_props = base.xml_properties(spawn_obj)
        check(f"spawn_facing_and_safe:{spawn_obj.attrib.get('name')}", spawn_props.get("facing") in {"north", "south", "east", "west"} and spawn_props.get("safe") is True, spawn_props)
    for npc_obj in root.findall("objectgroup[@name='NpcAnchor']/object"):
        npc_props = base.xml_properties(npc_obj)
        check(f"npc_schedule_contract:{npc_obj.attrib.get('name')}", bool(npc_props.get("scheduleRole")) and npc_props.get("travelMode") == "walk", npc_props)
    portal_group_props = base.xml_properties(portal_group) if portal_group is not None else {}
    check("portal_group_time_contract", portal_group_props.get("transitionConsumesGameTime") is False, portal_group_props)
    for portal_obj in portal_objects:
        portal_props = base.xml_properties(portal_obj)
        check(f"portal_time_contract:{portal_obj.attrib.get('name')}", portal_props.get("transitionConsumesGameTime") is False and "consumesGameTime" not in portal_props, portal_props)

    for group_name, id_property in (("Interaction", "interactionId"), ("StoryTrigger", "triggerId"), ("Buildable_Reserved", "plotId")):
        group = root.find(f"objectgroup[@name='{group_name}']")
        objects = group.findall("object") if group is not None else []
        for obj in objects:
            check(f"stable_id:{group_name}:{obj.attrib.get('name')}", bool(base.xml_properties(obj).get(id_property)), base.xml_properties(obj))

    for group_name, mask_name in (("Farmable", "Mask_Farmable"), ("Buildable_Free", "Mask_Buildable_Free"), ("Buildable_Reserved", "Mask_Buildable_Reserved"), ("NoBuild", "Mask_NoBuild")):
        group = root.find(f"objectgroup[@name='{group_name}']")
        props = base.xml_properties(group) if group is not None else {}
        check(f"bounds_group_mask_authority:{group_name}", props.get("boundsOnly") is True and props.get("maskLayer") == mask_name and props.get("authorityPriority") == "mask_over_bounds", props)
        if group is not None:
            check(f"bounds_objects_marked_only:{group_name}", all(base.xml_properties(obj).get("boundsOnly") is True for obj in group.findall("object")), len(group.findall("object")))

    def layer_cells(name: str, map_root: ET.Element = root) -> set[tuple[int, int]]:
        return {
            (index % MAP_W, index // MAP_W)
            for index, value in enumerate(base.parse_grid(base.layer_by_name(map_root, name)))
            if value
        }

    crossing_layer = base.layer_by_name(root, "Mask_Crossing_Development_Reclaimed")
    crossing_properties = base.xml_properties(crossing_layer)
    check("development_crossing_mask_exact", layer_cells("Mask_Crossing_Development_Reclaimed") == layout["unlockable_crossings"], len(layer_cells("Mask_Crossing_Development_Reclaimed") ^ layout["unlockable_crossings"]))
    check(
        "development_crossing_operation_complete",
        crossing_properties.get("operation") == "remove_water_collision_fishable_and_ecology_when_active"
        and crossing_properties.get("activationRule") == "at_or_above_reclaimed"
        and bool(crossing_properties.get("stableCrossingId")),
        crossing_properties,
    )
    pond_ecology = layer_cells("Mask_Fishing_Ecology_PondBrook")
    stream_ecology = layer_cells("Mask_Fishing_Ecology_SouthStream")
    check("fish_ecology_masks_disjoint", not (pond_ecology & stream_ecology), len(pond_ecology & stream_ecology))
    check("fish_ecology_covers_every_fishable_cell", (pond_ecology | stream_ecology) == layout["fishable_water"], len((pond_ecology | stream_ecology) ^ layout["fishable_water"]))

    ecology_group = root.find("objectgroup[@name='FishingEcologyZone']")
    ecology_objects = ecology_group.findall("object") if ecology_group is not None else []
    ecology_ids: set[str] = set()
    for obj in ecology_objects:
        props = base.xml_properties(obj)
        ecology_ids.add(str(props.get("ecologyZoneId", "")))
        check(f"fish_ecology_four_seasons:{obj.attrib.get('name')}", all(bool(props.get(f"{season}Profile")) for season in ("spring", "summer", "autumn", "winter")), props)

    anomaly_group = root.find("objectgroup[@name='AnomalyStateAnchor']")
    anomaly_objects = anomaly_group.findall("object") if anomaly_group is not None else []
    for obj in anomaly_objects:
        props = base.xml_properties(obj)
        x = round(float(obj.attrib.get("x", "0")) / TILE)
        y = round(float(obj.attrib.get("y", "0")) / TILE)
        check(f"anomaly_anchor_not_in_water:{obj.attrib.get('name')}", (x, y) not in layout["water"] and props.get("waterPlacement") is False, (x, y))
        check(f"anomaly_anchor_stable_contract:{obj.attrib.get('name')}", bool(props.get("stableId")) and bool(props.get("target")) and props.get("collisionChange") is False and props.get("geometryChange") is False, props)

    semantic_layer_names = [name for name in layer_names if name.startswith("Mask_") or name == "Bridge_Mask"]
    for name in semantic_layer_names:
        nonzero = {value for value in base.parse_grid(base.layer_by_name(root, name)) if value}
        check(f"semantic_layer_uses_logic_gid:{name}", not nonzero or min(nonzero) >= LOGIC_FIRST_GID, sorted(nonzero)[:8])

    logic_root = ET.parse(BATCH_ROOT / "source/tilesets/h01_layout_logic.tsx").getroot()
    crossing_logic_tile = logic_root.find(f"tile[@id='{base.LOGIC_CROSSING_OVERRIDE}']")
    crossing_logic_props = base.xml_properties(crossing_logic_tile) if crossing_logic_tile is not None else {}
    check(
        "crossing_logic_operation_complete",
        crossing_logic_props.get("operation") == "remove_water_collision_fishable_and_ecology_when_active"
        and crossing_logic_props.get("removesFishableEligibility") is True
        and crossing_logic_props.get("removesFishingEcologyProfile") is True,
        crossing_logic_props,
    )
    for tile_id, ecology_id in (
        (LOGIC_FISH_ECOLOGY_POND_BROOK, "fish_ecology.h01.pond_brook"),
        (LOGIC_FISH_ECOLOGY_SOUTH_STREAM, "fish_ecology.h01.south_stream"),
    ):
        tile = logic_root.find(f"tile[@id='{tile_id}']")
        tile_props = base.xml_properties(tile) if tile is not None else {}
        check(f"fishing_ecology_logic:{tile_id}", tile_props.get("semanticId") == ecology_id and tile_props.get("operation") == "set_profile", tile_props)

    for layer in root.findall("layer"):
        props = base.xml_properties(layer)
        if props.get("stateAxis") in {"development", "season", "anomaly"}:
            check(f"state_layer_uses_state_value:{layer.attrib.get('name')}", bool(props.get("stateValue")), props)
    path_hint_layer = base.layer_by_name(root, "Development_Derelict_PathHint")
    path_hint_props = base.xml_properties(path_hint_layer)
    derelict_grid = base.parse_grid(path_hint_layer)
    check("future_path_hints_present", len(layout["future_path_hint_cells"]) >= 6 and layout["future_path_hint_cells"] <= (layout["unlockable_path"] - layout["water"]), len(layout["future_path_hint_cells"]))
    check("future_path_hints_visible_in_derelict", all(derelict_grid[idx(point)] != 0 for point in layout["future_path_hint_cells"]), len(layout["future_path_hint_cells"]))
    check("future_path_hint_layer_contract", path_hint_layer.attrib.get("visible", "1") != "0" and path_hint_props.get("stateAxis") == "development" and path_hint_props.get("stateValue") == "derelict" and path_hint_props.get("authority") == "visual_only_no_gameplay_permission", path_hint_props)
    fishing_points = ((92, 43, "fish_ecology.h01.pond_brook"), (101, 48, "fish_ecology.h01.pond_brook"), (99, 63, "fish_ecology.h01.pond_brook"), (77, 83, "fish_ecology.h01.south_stream"))
    fishing_group = root.find("objectgroup[@name='FishingAccessQA']")
    fishing_objects_by_cell = {
        (round(float(obj.attrib.get("x", "0")) / TILE), round(float(obj.attrib.get("y", "0")) / TILE)): obj
        for obj in (fishing_group.findall("object") if fishing_group is not None else [])
    }
    for x, y, ecology_zone_id in fishing_points:
        point = (x, y)
        check(f"fishing_qa_walkable:{point}", point in walkable, point)
        check(f"fishing_qa_adjacent_water:{point}", any(neighbor in layout["water"] for neighbor in base.neighbors4(point)), point)
        obj = fishing_objects_by_cell.get(point)
        check(f"fishing_qa_ecology:{point}", obj is not None and base.xml_properties(obj).get("ecologyZoneId") == ecology_zone_id and ecology_zone_id in ecology_ids, base.xml_properties(obj) if obj is not None else "missing")
    near = {p for p in layout["farmable"] if math.dist(p, HOME_SPAWN) <= 14}
    far = {p for p in layout["farmable"] if math.dist(p, HOME_SPAWN) >= 50}
    near_density = len(layout["debris_cells"] & near) / max(1, len(near))
    far_density = len(layout["debris_cells"] & far) / max(1, len(far))
    check("debris_present_near_home", near_density > 0.02, f"{near_density:.4f}")
    check("debris_continuous_falloff", near_density < far_density, f"near={near_density:.4f};far={far_density:.4f}")
    check("debris_quantity", len(layout["debris_cells"]) > 1200, len(layout["debris_cells"]))
    for key, path in reviews.items():
        review_root = ET.parse(path).getroot()
        check(f"review_parse:{key}", base.xml_properties(review_root).get("derivedPreviewOnly") is True, path.name)
    derelict_root = ET.parse(reviews["spring_derelict_normal"]).getroot()
    built_root = ET.parse(reviews["spring_built_normal"]).getroot()
    check("derelict_future_crossing_remains_colliding", layer_cells("Mask_Collision_Water", derelict_root) == (layout["water"] - layout["permanent_crossings"]), len(layer_cells("Mask_Collision_Water", derelict_root) ^ (layout["water"] - layout["permanent_crossings"])))
    check("mature_future_crossing_collision_removed", layer_cells("Mask_Collision_Water", built_root) == (layout["water"] - layout["permanent_crossings"] - layout["unlockable_crossings"]), len(layer_cells("Mask_Collision_Water", built_root) ^ (layout["water"] - layout["permanent_crossings"] - layout["unlockable_crossings"])))
    mature_pond_ecology = layer_cells("Mask_Fishing_Ecology_PondBrook", built_root)
    mature_stream_ecology = layer_cells("Mask_Fishing_Ecology_SouthStream", built_root)
    mature_fishable = layout["fishable_water"] - layout["unlockable_crossings"]
    check("mature_crossing_not_fishable", not (layout["unlockable_crossings"] & (mature_pond_ecology | mature_stream_ecology)), len(layout["unlockable_crossings"] & (mature_pond_ecology | mature_stream_ecology)))
    check("mature_ecology_exact_after_crossing_removal", not (mature_pond_ecology & mature_stream_ecology) and (mature_pond_ecology | mature_stream_ecology) == mature_fishable, len((mature_pond_ecology | mature_stream_ecology) ^ mature_fishable))
    check("mature_review_declares_cumulative", base.xml_properties(built_root).get("reviewDevelopment") == "mature" and base.xml_properties(built_root).get("reviewDevelopmentComposition") == "cumulative", base.xml_properties(built_root))
    for key, path in rendered.items():
        with Image.open(path) as image:
            check(f"tiled_render:{key}", image.size == (4096, 3072), image.size)
    a = Image.open(rendered["spring_derelict_normal"]).convert("RGB").resize((640, 480), Image.Resampling.NEAREST)
    b = Image.open(rendered["spring_built_normal"]).convert("RGB").resize((640, 480), Image.Resampling.NEAREST)
    diff = ImageChops.difference(a, b)
    changed_bbox = diff.getbbox()
    changed = 0.0 if changed_bbox is None else (
        sum(1 for px in diff.get_flattened_data() if px != (0, 0, 0)) / (640 * 480)
    )
    check("derelict_built_visual_difference", changed > 0.015, f"{changed:.6f}")
    for name in ("h01_layout_annotated_cn_2400x1320.png", "h01_derelict_built_compare_cn_2400x1030.png"):
        check(f"review_board:{name}", (BATCH_ROOT / "previews" / name).is_file(), name)
    for key in reviews:
        south_portal_preview = BATCH_ROOT / "previews" / f"h01_review_{key}_south_portal_640x360.png"
        check(f"south_portal_review_crop:{key}", south_portal_preview.is_file(), south_portal_preview.name)
        future_route_preview = BATCH_ROOT / "previews" / f"h01_review_{key}_future_route_640x360.png"
        check(f"future_route_review_crop:{key}", future_route_preview.is_file(), future_route_preview.name)

    contract_path = REPO_ROOT / "art-source/maps/estate-pipeline-v1/TILED_TO_GODOT_DISPOSITION_V1.json"
    handoff_path = BATCH_ROOT / "H01_GODOT_IMPORT_HANDOFF.json"
    check("disposition_contract_exists", contract_path.is_file(), contract_path)
    check("godot_handoff_exists", handoff_path.is_file(), handoff_path)
    if contract_path.is_file():
        contract = json.loads(contract_path.read_text(encoding="utf-8"))
        syntax = contract.get("matchSyntax", {})
        check("disposition_match_syntax_explicit", syntax.get("name") == "pipe_separated_full_name_glob_v1" and syntax.get("alternationSeparator") == "|" and syntax.get("regex") is False, syntax)
        rules = contract.get("layerDisposition", [])
        crossing_rules = [rule for rule in rules if rule.get("match") == "Mask_Crossing_*"]
        ecology_rules = [rule for rule in rules if rule.get("match") == "Mask_Fishing_Ecology_*"]
        visual_rules = [rule for rule in rules if "Portal_*_Visual" in str(rule.get("match", ""))]
        check("disposition_crossing_rule", len(crossing_rules) == 1 and "remove_water_collision_fishable_and_ecology_when_active" in crossing_rules[0].get("allowedLayerOperations", []) and crossing_rules[0].get("missingOperation") == "error", crossing_rules)
        check("disposition_fishing_ecology_rule", len(ecology_rules) == 1 and ecology_rules[0].get("operation") == "set_profile" and ecology_rules[0].get("kind") == "semantic_profile_grid", ecology_rules)
        check("disposition_conditional_portal_visual_rule", len(visual_rules) == 1, visual_rules)
        object_rules = contract.get("objectDisposition", {})
        ecology_object_rules = [value for key, value in object_rules.items() if "fishing_ecology_zone" in key]
        check("disposition_fishing_ecology_object_rule", len(ecology_object_rules) == 1 and "semantic masks" in ecology_object_rules[0], ecology_object_rules)
        check("disposition_occlusion_object_rule", "runtime occlusion-region metadata" in str(object_rules.get("occlusion", "")) and "no implicit collision" in str(object_rules.get("occlusion", "")), object_rules.get("occlusion"))
        check("disposition_fishing_access_qa_object_rule", "discard from runtime scene" in str(object_rules.get("fishing_access_qa", "")) and "never instantiate a fixed fishing spot" in str(object_rules.get("fishing_access_qa", "")), object_rules.get("fishing_access_qa"))
    if handoff_path.is_file():
        handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
        development = handoff.get("development", {})
        fishing_handoff = handoff.get("fishing", {})
        conditional_portal = handoff.get("conditionalPortal", {})
        check("handoff_crossing_contract", development.get("crossingMask") == "Mask_Crossing_Development_Reclaimed" and development.get("crossingOperation") == "remove_water_collision_fishable_and_ecology_when_active", development)
        check("handoff_fishing_state_precedence", "removes collision, fishable eligibility and ecology profile" in str(fishing_handoff.get("crossingStateRemovalPrecedence", "")), fishing_handoff)
        check("handoff_conditional_portal_visual", conditional_portal.get("lockedVisualLayer") == "Portal_Future_Region_Locked_Visual" and conditional_portal.get("transitionConsumesGameTime") is False, conditional_portal)
    for path in BATCH_ROOT.rglob("*"):
        if path.is_file():
            check(f"d_drive:{path.relative_to(BATCH_ROOT).as_posix()}", path.drive.upper() == "D:", path.resolve())

    passed = sum(item["passed"] for item in checks)
    report = {"schemaVersion": 1, "batchId": BATCH_ID, "mapId": MAP_ID, "status": "passed" if passed == len(checks) else "failed", "checksPassed": passed, "checksTotal": len(checks), "checks": checks}
    output = BATCH_ROOT / "H01_LAYOUT_VALIDATION.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if passed != len(checks):
        raise RuntimeError([item for item in checks if not item["passed"]][:10])
    return output


def file_description(path: Path) -> tuple[str, str]:
    if path.suffix.lower() == ".png":
        with Image.open(path) as image:
            return "PNG", f"{image.width}x{image.height} px; {image.mode}"
    if path.suffix.lower() == ".tmx":
        root = ET.parse(path).getroot()
        return "TMX", f"{root.attrib['width']}x{root.attrib['height']} tiles; {root.attrib['tilewidth']}x{root.attrib['tileheight']} px"
    if path.suffix.lower() == ".tsx":
        root = ET.parse(path).getroot()
        return "TSX", f"{root.attrib['tilecount']} tiles; {root.attrib['tilewidth']}x{root.attrib['tileheight']} px"
    return path.suffix[1:].upper(), "UTF-8" if path.suffix.lower() in {".json", ".md", ".py"} else "binary"


def write_file_index() -> Path:
    output = BATCH_ROOT / "H01_LAYOUT_FILE_INDEX.md"
    paths = [p for p in sorted(BATCH_ROOT.rglob("*")) if p.is_file() and p != output]
    lines = [
        "# H01 开阔草甸 Batch 001 文件索引", "",
        "全部文件位于 D 盘。该索引自身不记录 SHA-256；其余文件均记录绝对路径、格式、尺寸、字节数、来源与授权边界。", "",
        "| 绝对路径 | 格式 | 尺寸/结构 | 字节 | SHA-256 | 来源与授权 |",
        "| --- | --- | --- | ---: | --- | --- |",
    ]
    for path in paths:
        fmt, dimensions = file_description(path)
        if "/source/tilesets/" in path.as_posix():
            source = "H03 标杆项目自有像素经 H02 已验证布局图集流程复用；未复制概念图像素"
        elif path.suffix.lower() == ".png":
            source = "Tiled 实际栅格化或项目自制 Pillow 审阅排版"
        else:
            source = "项目自制确定性地图生产文件"
        lines.append(f"| `{path.resolve()}` | {fmt} | {dimensions} | {path.stat().st_size} | `{sha256(path)}` | {source}；内部候选，`shippingApproval=false` |")
    lines.append(f"| `{output.resolve()}` | Markdown | UTF-8；self-index | 写入后确定 | self-referential-not-recorded | 项目自制索引；`shippingApproval=false` |")
    lines.extend(("", f"索引条目总数：{len(paths)+1}。", ""))
    output.write_text("\n".join(lines), encoding="utf-8")
    return output


def main() -> int:
    if BATCH_ROOT.drive.upper() != "D:" or REPO_ROOT.drive.upper() != "D:":
        raise RuntimeError(f"D-drive boundary violated: {BATCH_ROOT}; {REPO_ROOT}")
    tiled = Path(r"D:\lzq\Tiled\tmxrasterizer.exe")
    font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
    if not tiled.is_file() or not font_path.is_file():
        raise FileNotFoundError(f"Tiled/font unavailable: {tiled}; {font_path}")
    prepare_tilesets()
    layout = build_layout()
    authoritative = build_authoritative(layout)
    reviews = build_reviews(authoritative, layout)
    rendered = render_reviews(reviews, tiled, font_path)
    write_records(authoritative, layout, font_path)
    validation = validate(authoritative, reviews, rendered, layout)
    index_path = write_file_index()
    report = json.loads(validation.read_text(encoding="utf-8"))
    print(json.dumps({
        "batchRoot": str(BATCH_ROOT), "authoritativeTmx": str(authoritative),
        "validation": f"{report['checksPassed']}/{report['checksTotal']}",
        "fileIndex": str(index_path),
        "functionalCounts": {
            "water": len(layout["water"]), "farmable": len(layout["farmable"]),
            "buildableFree": len(layout["buildable_free"]), "reserved": len(layout["buildable_reserved"]),
            "debris": len(layout["debris_cells"]), "heavyDebris": len(layout["heavy_debris_cells"]),
        },
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
