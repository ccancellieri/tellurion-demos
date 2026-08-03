import json
import unittest
from pathlib import Path

from scripts.harvest_esa_worldcover import HarvestError, validate_and_derive


FIXTURES = Path(__file__).parent / "fixtures" / "stac"


def load(name: str) -> dict:
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


class HarvestContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.collection = load("collection.json")
        self.search = load("item-search.json")

    def test_derives_exact_worldcover_palette_and_source_identity(self):
        result = validate_and_derive(self.collection, self.search)
        self.assertEqual(result.item["id"], "ESA_WorldCover_10m_2021_v200_N39E012")
        self.assertEqual(result.footprint["features"][0]["id"], 1)
        self.assertEqual(
            result.footprint["features"][0]["properties"]["source_item_id"],
            result.item["id"],
        )
        self.assertEqual(
            [entry["value"] for entry in result.legend],
            [10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 100],
        )
        self.assertEqual(result.legend[0]["color"], "#006400")

    def test_rejects_an_unexpected_item(self):
        self.search["features"][0]["id"] = "another-item"
        with self.assertRaisesRegex(HarvestError, "unexpected Item"):
            validate_and_derive(self.collection, self.search)

    def test_rejects_a_duplicate_class_value(self):
        classes = self.search["features"][0]["assets"]["map"]["classification:classes"]
        classes[1]["value"] = classes[0]["value"]
        with self.assertRaisesRegex(HarvestError, "duplicate class value"):
            validate_and_derive(self.collection, self.search)

    def test_rejects_a_malformed_color(self):
        classes = self.search["features"][0]["assets"]["map"]["classification:classes"]
        classes[0]["color-hint"] = "green"
        with self.assertRaisesRegex(HarvestError, "color-hint"):
            validate_and_derive(self.collection, self.search)

    def test_rejects_a_non_cog_map_asset(self):
        self.search["features"][0]["assets"]["map"]["type"] = "image/tiff"
        with self.assertRaisesRegex(HarvestError, "Cloud Optimized GeoTIFF"):
            validate_and_derive(self.collection, self.search)
