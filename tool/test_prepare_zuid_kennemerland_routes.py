import json
from pathlib import Path
import unittest

from prepare_zuid_kennemerland_routes import ParkClipper, prepare, path_length_meters


class ParkClipperTest(unittest.TestCase):
    def setUp(self):
        self.geometry = {'type': 'Polygon', 'coordinates': [
            [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]],
            [[4, 4], [6, 4], [6, 6], [4, 6], [4, 4]],
        ]}
        self.clipper = ParkClipper(self.geometry)

    def test_crossing_a_hole_splits_the_path(self):
        self.assertEqual(self.clipper.clip_line([[-1, 5], [11, 5]]), [
            [[0.0, 5.0], [4.0, 5.0]], [[6.0, 5.0], [10.0, 5.0]],
        ])

    def test_line_on_the_boundary_is_retained(self):
        self.assertEqual(self.clipper.clip_line([[-1, 0], [11, 0]]), [
            [[0.0, 0.0], [10.0, 0.0]],
        ])

    def test_leaving_and_reentering_splits_parts(self):
        self.assertEqual(self.clipper.clip_line([[1, 1], [12, 1], [12, 9], [1, 9]]), [
            [[1.0, 1.0], [10.0, 1.0]], [[10.0, 9.0], [1.0, 9.0]],
        ])

    def test_outside_routes_are_removed_and_source_id_is_preserved(self):
        routes = {'features': [
            {'properties': {'OBJECTID': 7, 'naam': 'Binnenroute'}, 'geometry': {'type': 'LineString', 'coordinates': [[1, 1], [2, 2]]}},
            {'properties': {'OBJECTID': 8, 'naam': 'Buitenroute'}, 'geometry': {'type': 'LineString', 'coordinates': [[20, 20], [21, 21]]}},
        ]}
        result = prepare(routes, {'geometry': self.geometry})
        self.assertEqual(len(result['features']), 1)
        self.assertEqual(result['features'][0]['properties']['OBJECTID'], 7)
        self.assertEqual(result['features'][0]['properties']['park_id'], 'np-zuid-kennemerland')

    def test_crossing_routes_keep_their_complete_geometry_and_source_length(self):
        geometry = {'type': 'MultiLineString', 'coordinates': [
            [[-1, 2], [5, 2], [11, 2]], [[2, 3], [3, 3]],
        ]}
        routes = {'features': [{'properties': {'OBJECTID': 9, 'naam': 'Hele route', 'Shape.STLength()': 123}, 'geometry': geometry}]}
        original = json.dumps(routes, sort_keys=True)
        result = prepare(routes, {'geometry': self.geometry})
        self.assertEqual(result['features'][0]['geometry'], geometry)
        self.assertEqual(result['features'][0]['properties']['Shape.STLength()'], 123)
        self.assertEqual(json.dumps(routes, sort_keys=True), original)

    def test_short_unnamed_paths_are_excluded_even_with_an_entrance(self):
        geometry = {'type': 'LineString', 'coordinates': [[1, 1], [1.001, 1]]}
        routes = {'features': [
            {'properties': {'OBJECTID': 1, 'naam': '  ', 'naamingang': 'Ingang'}, 'geometry': geometry},
            {'properties': {'OBJECTID': 2, 'naam': None}, 'geometry': geometry},
            {'properties': {'OBJECTID': 3, 'naampwn': 'PWN route'}, 'geometry': geometry},
        ]}
        self.assertEqual([f['properties']['OBJECTID'] for f in prepare(routes, {'geometry': self.geometry})['features']], [3])

    def test_long_unnamed_paths_keep_source_geometry_and_short_parts_do_not_gain_gap_distance(self):
        long_geometry = {'type': 'LineString', 'coordinates': [[1, 1], [1.006, 1]]}
        short_parts = {'type': 'MultiLineString', 'coordinates': [
            [[1, 1], [1.001, 1]], [[2, 2], [2.001, 2]],
        ]}
        routes = {'features': [
            {'properties': {'OBJECTID': 1}, 'geometry': long_geometry},
            {'properties': {'OBJECTID': 2}, 'geometry': short_parts},
        ]}
        result = prepare(routes, {'geometry': self.geometry})
        self.assertEqual([f['properties']['OBJECTID'] for f in result['features']], [1])
        self.assertEqual(result['features'][0]['geometry'], long_geometry)
        self.assertNotIn('naam', result['features'][0]['properties'])
        self.assertLess(path_length_meters(short_parts['coordinates']), 600)

    def test_all_bundled_paths_intersect_the_park_without_requiring_every_point_inside(self):
        assets = Path(__file__).resolve().parents[1] / 'src/assets/routes'
        park = json.loads((assets / 'zuid_kennemerland_boundary.geojson').read_text())
        routes = json.loads((assets / 'park_walking_routes.geojson').read_text())
        clipper = ParkClipper(park['geometry'])
        self.assertEqual(park['properties']['naam'], 'Zuid-Kennemerland')
        self.assertEqual(len(routes['features']), 38)
        for feature in routes['features']:
            geometry = feature['geometry']
            lines = [geometry['coordinates']] if geometry['type'] == 'LineString' else geometry['coordinates']
            self.assertTrue(any(clipper.clip_line(line) for line in lines), feature['properties']['OBJECTID'])
            named = any(str(feature['properties'].get(key) or '').strip() for key in ('naam', 'naampwn'))
            self.assertTrue(named or path_length_meters(lines) >= 600)


if __name__ == '__main__':
    unittest.main()
