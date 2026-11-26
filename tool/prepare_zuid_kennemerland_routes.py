"""Select supplied walking lines intersecting PDOK's Zuid-Kennemerland polygon.

Usage: python3 tool/prepare_zuid_kennemerland_routes.py ROUTES_JSON PARKS_GEOJSON
The second input can be a PDOK FeatureCollection or the park Feature itself.
No third-party dependencies; the original input files are never modified.
"""

import json
import math
from pathlib import Path
import sys

EPS = 1e-12
MIN_UNNAMED_PATH_METERS = 600


def path_length_meters(lines):
    """Sum actual WGS84 line parts, without bridging disconnected pieces."""
    total = 0.0
    for line in lines:
        for a, b in zip(line, line[1:]):
            lat1, lat2 = math.radians(a[1]), math.radians(b[1])
            delta_lon = math.radians(b[0] - a[0])
            value = (math.sin((lat2 - lat1) / 2) ** 2
                     + math.cos(lat1) * math.cos(lat2) * math.sin(delta_lon / 2) ** 2)
            total += 6371000 * 2 * math.asin(min(1, math.sqrt(value)))
    return total


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def delta(a, b):
    return b[0] - a[0], b[1] - a[1]


def close(a, b):
    return abs(a[0] - b[0]) < EPS and abs(a[1] - b[1]) < EPS


class ParkClipper:
    """Even/odd polygon membership includes boundaries and excludes holes.

    Split each line edge at ALL park-ring intersections; retain only inside
    intervals. Outside intervals break the output line, never join across gaps.
    Latitude buckets accelerate point queries without changing the geometry.
    """

    def __init__(self, geometry):
        polygons = geometry['coordinates'] if geometry['type'] == 'MultiPolygon' else [geometry['coordinates']]
        self.edges = [(a, b) for polygon in polygons for ring in polygon
                      for a, b in zip(ring, ring[1:]) if not close(a, b)]
        points = [p for edge in self.edges for p in edge]
        self.bounds = (min(p[0] for p in points), min(p[1] for p in points),
                       max(p[0] for p in points), max(p[1] for p in points))
        self.buckets = [[] for _ in range(256)]
        for edge in self.edges:
            low, high = sorted((edge[0][1], edge[1][1]))
            for index in range(self.bucket(low), self.bucket(high) + 1):
                self.buckets[index].append(edge)

    def bucket(self, y):
        return max(0, min(255, int((y - self.bounds[1]) / (self.bounds[3] - self.bounds[1]) * 255)))

    def covers(self, point):
        x, y = point
        west, south, east, north = self.bounds
        if x < west - EPS or x > east + EPS or y < south - EPS or y > north + EPS:
            return False
        inside = False
        for a, b in self.buckets[self.bucket(y)]:
            ab = delta(a, b)
            ap = delta(a, point)
            if (min(a[0], b[0]) - EPS <= x <= max(a[0], b[0]) + EPS and
                    min(a[1], b[1]) - EPS <= y <= max(a[1], b[1]) + EPS and
                    abs(cross(ab, ap)) <= EPS * math.hypot(*ab)):
                return True
            if (a[1] > y) != (b[1] > y):
                if x < a[0] + (y - a[1]) * ab[0] / ab[1]:
                    inside = not inside
        return inside

    def intervals(self, a, b):
        ab = delta(a, b)
        length_sq = ab[0] ** 2 + ab[1] ** 2
        if length_sq < EPS ** 2:
            return []
        cuts = [0.0, 1.0]
        low, high = sorted((a[1], b[1]))
        candidates = set()
        for index in range(self.bucket(low), self.bucket(high) + 1):
            for c, d in self.buckets[index]:
                candidates.add((tuple(c), tuple(d)))
        for c, d in candidates:
            if (max(c[0], d[0]) < min(a[0], b[0]) - EPS or
                    min(c[0], d[0]) > max(a[0], b[0]) + EPS):
                continue
            cd = delta(c, d)
            ac = delta(a, c)
            denominator = cross(ab, cd)
            if abs(denominator) > 1e-20:
                t, u = cross(ac, cd) / denominator, cross(ac, ab) / denominator
                if -EPS <= t <= 1 + EPS and -EPS <= u <= 1 + EPS:
                    cuts.append(max(0.0, min(1.0, t)))
            elif abs(cross(ab, ac)) <= EPS * math.hypot(*ab):
                for point in (c, d):
                    ap = delta(a, point)
                    t = (ap[0] * ab[0] + ap[1] * ab[1]) / length_sq
                    if 0 < t < 1:
                        cuts.append(t)
        cuts.sort()
        result = []
        for start, end in zip(cuts, cuts[1:]):
            if end - start <= EPS:
                continue
            mid = (start + end) / 2
            if self.covers((a[0] + mid * ab[0], a[1] + mid * ab[1])):
                result.append(([a[0] + start * ab[0], a[1] + start * ab[1]],
                               [a[0] + end * ab[0], a[1] + end * ab[1]]))
        return result

    def clip_line(self, line):
        result = []
        current = []
        for a, b in zip(line, line[1:]):
            for start, end in self.intervals(a, b):
                if current and not close(current[-1], start):
                    if len(current) > 1:
                        result.append(current)
                    current = []
                if not current:
                    current.append(start)
                if not close(current[-1], end):
                    current.append(end)
        if len(current) > 1:
            result.append(current)
        return result


def prepare(routes, park):
    clipper = ParkClipper(park['geometry'])
    features = []
    for feature in routes['features']:
        geometry = feature['geometry']
        lines = [geometry['coordinates']] if geometry['type'] == 'LineString' else geometry['coordinates']
        named = any(str(feature['properties'].get(key) or '').strip()
                    for key in ('naam', 'naampwn'))
        if not named and path_length_meters(lines) < MIN_UNNAMED_PATH_METERS:
            continue
        intersects = any(clipper.clip_line(line) for line in lines)
        if intersects:
            properties = dict(feature['properties'])
            properties['park_id'] = 'np-zuid-kennemerland'
            # Select by intersection, but preserve the complete source lines:
            # cutting a walking route at the park border can break its loop.
            features.append({'type': 'Feature', 'properties': properties,
                             'geometry': geometry})
    return {'type': 'FeatureCollection', 'name': 'Zuid-Kennemerland walking paths',
            'features': features}


def main():
    routes = json.loads(Path(sys.argv[1]).read_text())
    parks = json.loads(Path(sys.argv[2]).read_text())
    park = next(f for f in parks['features'] if f['properties']['naam'] == 'Zuid-Kennemerland') if parks['type'] == 'FeatureCollection' else parks
    if park['properties']['naam'] != 'Zuid-Kennemerland':
        raise ValueError('Expected the official Zuid-Kennemerland feature')
    result = prepare(routes, park)
    destination = Path(__file__).resolve().parents[1] / 'src/assets/routes'
    destination.mkdir(parents=True, exist_ok=True)
    for filename, document in [('park_walking_routes.geojson', result), ('zuid_kennemerland_boundary.geojson', park)]:
        # Keep the generated assets compact without rounding coordinates.
        (destination / filename).write_text(json.dumps(document, ensure_ascii=False, separators=(',', ':')) + '\n')
    print(f"Kept {len(result['features'])} of {len(routes['features'])} paths intersecting Zuid-Kennemerland, with original geometry")


if __name__ == '__main__':
    main()
