# Zuid-Kennemerland walking paths and park boundary

Walking data: `geojson.json` from the user-supplied `wandelroutes.zip`, received
18 November 2026. The original contains 98 coastal trails/path features. The
bundled subset contains 38 features intersecting the published park polygon:
all 12 source-named trails and 26 unnamed paths at least 600 metres long. Eight
shorter unnamed paths are excluded. Unnamed paths use a neutral `Wandelpad ID`
label; lengths sum only actual line parts, never the gaps between them. No names, entrances, operators, access status or route connections are
invented. Source attributes, IDs and all original coordinates/line parts are
retained. A route can extend outside the national park; it is not clipped at
the boundary. This is a map overlay, without turn-by-turn navigation.

Park boundary: the Zuid-Kennemerland feature from RVO's Nationale Parken dataset,
served by PDOK and retrieved 19 November 2026. The actual MultiPolygon contains
one outer ring and five holes (2,342 coordinates); all six outlines are drawn.
It does not replace the app's existing living-lab/location-sharing geometry.

- Dataset: https://www.pdok.nl/ogc-apis/-/article/nationale-parken
- Feature: https://api.pdok.nl/rvo/nationale-parken/ogc/v1/collections/nationaleparken/items/92136302-949b-5d95-9269-cab51838aa84?f=json

Both bundled files use WGS84 longitude/latitude. Distances are approximate sums
along the original separate lines; gaps between parts are never connected or
included in the distance. The renderer simplifies lines within two metres for
display and culls off-screen lines; original geometry remains available for
distance and camera bounds. Bundled overlays need no network request. Basemap
tiles retain the app's existing network/cache behaviour.

To regenerate from the original GeoJSON and a PDOK park Feature/FeatureCollection,
run from the repository root:

    python3 tool/prepare_zuid_kennemerland_routes.py /path/to/geojson.json /path/to/park.geojson
    python3 -m unittest discover -s tool -p 'test_prepare*.py'

Selection uses geometric intersection, including polygon holes, rather than a
bounding box. Geometry crossing the boundary is retained whole.

## Trail selection, distances and directions

Selecting Zuid-Kennemerland shows all 38 retained routes and paths. Selecting a trail shows
only that trail; “Alle routes” restores the overview without stopping a walk. A separate map button hides/shows the trail layer.
Map taps are matched to the visible separate line parts with a 48-logical-pixel
touch width; shared lines offer a route choice. The searchable route list is
also available for users who cannot select a line precisely.

The detail card measures approximate straight-line distance from the actual
MapProvider GPS position to the nearest original trail segment. It never uses
the camera centre or report/map selection. Missing GPS is shown as unavailable;
an older fix is labelled as the last GPS location. This is not travel distance.

`confirmed_entrances.json` is a separate, explicit navigation allowlist, checked
19 November 2026 against the entrance layer in the Google map currently embedded
on the national park's official overview page. Its six points match the
published entrance pins exactly. Twelve named trails are linked using their
supplied `naamingang` attributes. Parnassia/Parnassiaweg and
Elswout/Buitenplaats Elswout are explicit name mappings, cross-checked against
the official entrance list. Two trails list two confirmed entrance choices.
The file records URLs, verification date and the downloaded KML's SHA-256.

- Official map: https://www.np-zuidkennemerland.nl/gebiedsinformatie/overzichtskaart/
- Entrance names: https://www.np-zuidkennemerland.nl/gebiedsinformatie/ingangen/
- Embedded map: https://www.google.com/maps/d/viewer?mid=1yhMuEPiDde25OETu9NBjBm6LQzxy3U8

No nearest-amenity, trail endpoint, entrance-name guess or camera position can
enable directions. Any path without a confirmed entrance keeps navigation
disabled. Confirmation here means the entrance is published on the official
park map; it is not a claim of a staff field inspection or current access status.
Other amenities retain their existing review status. New or changed navigation
entries must include a source-confirmed point and an explicit route association.

Starting/resuming a walk uses the existing local recorder, consent, pause/resume
and sighting flow. A paused walk is retained. The chosen outline stays visible. Starting or resuming follows actual GPS
while preserving the current zoom level; panning stops camera follow. Missing
GPS never uses a report selection or entrance as the user position. This feature does not add turn-by-turn guidance or backend route storage.
