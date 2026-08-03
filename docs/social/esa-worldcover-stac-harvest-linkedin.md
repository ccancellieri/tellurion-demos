# LinkedIn launch copy — ESA WorldCover STAC harvest

I wanted to test a simple question: can a STAC record keep its meaning all the
way from discovery to a live, dynamically rendered map?

I harvested one bounded ESA WorldCover Item covering Rome. The preserved source
STAC metadata describes its Cloud Optimized GeoTIFF and the exact colors for the
eleven land-cover classes.

The demo keeps that source document and its provenance, validates the class
metadata into digest-linked colormap and legend evidence, routes the Item
footprint through GeoPackage and the raster data through the COG driver, then
exposes STAC and OGC API Features resources, raster TileSet metadata, and live
PNG tiles.

The WorldCover COG is paletted, so Tellurion uses its embedded authoritative
colors at runtime. The generated colormap and legend prove that the harvested
class meaning was preserved; they are not applied as a rendering override.

The important boundary: the COG is an asset; the dynamic APIs are links. The
harvest happens during release, not while serving requests, and unsupported
remote style instructions are never executed.

Live demo: https://ccancellieri.github.io/tellurion-demos/demos/stac/

Article: https://github.com/ccancellieri/tellurion-demos/blob/main/docs/articles/from-stac-discovery-to-a-live-map.md

Source and reproducibility: https://github.com/ccancellieri/tellurion-demos

#STAC #OGCAPI #CloudOptimizedGeoTIFF #Rust #Geospatial #OpenStandards
