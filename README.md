# Tellurion demos

A human-first, reproducible gallery for Tellurion's vector, raster,
multidimensional, 3D, filtering, catalog and server-rendering paths.

**Visual entry point:** <https://ccancellieri.github.io/tellurion-demos/>

The public gallery and each live backend are checked daily by the
[`Public demo smoke test`](https://github.com/ccancellieri/tellurion-demos/actions/workflows/smoke.yml).

This repository intentionally separates the public landing pages from the
machine-readable OGC API endpoints. Start with the visual gallery; use the API
links when you want to inspect the protocol payloads.

## What the gallery demonstrates

| Lane | Public viewer | Tellurion path | Evidence boundary |
|---|---|---|---|
| Vector | [Interactive road map](https://ccancellieri.github.io/tellurion-demos/demos/vector/) | GeoPackage → OGC API Features and MVT | 5,603-feature OpenStreetMap case sample |
| Raster | [Interactive land-cover map](https://ccancellieri.github.io/tellurion-demos/demos/raster/) | COG → OGC API Tiles/Maps PNG | ESA WorldCover sample, correctly attributed |
| Zarr | [Two-slice comparison](https://ccancellieri.github.io/tellurion-demos/demos/zarr/) | Zarr v2 shape `[time, y, x]` → PNG | Synthetic fixed slices; no on-wire dimension-selection claim |
| 3D | [Interactive GLB scene](https://ccancellieri.github.io/tellurion-demos/demos/3d/) | polygons → MVT → extrusion → GLB/3D Tiles 1.1 | Synthetic footprints; no OGC API 3D GeoVolumes conformance claim |
| CQL2 | [Live query workbench](https://ccancellieri.github.io/tellurion-demos/demos/query/) | CQL2 text → GeoPackage filter → GeoJSON | Bounded to 50 features and this driver's advertised filter classes |
| STAC | [Linked catalog projection](https://ccancellieri.github.io/tellurion-demos/demos/stac/) | canonical collection → STAC Collection and Items | Feature projection only; no source-asset inventory claim |
| Maps + Styles | [Server-rendered Rome map](https://ccancellieri.github.io/tellurion-demos/demos/maps/) | MVT mosaic → PNG, optionally painted by MapLibre Style JSON | Maps 1.0 path; Styles surface is draft-aligned and read-only |

Render's free services can sleep after inactivity, so a viewer may need a short
cold start. Hosted response times are not benchmark evidence.

## Public services

The Render Blueprint defines four read-only services:

- `tellurion-vector-demo` — GeoPackage-backed Features and vector tiles.
- `tellurion-raster-demo` — Cloud Optimized GeoTIFF-backed raster tiles from `sample_landcover`.
- `tellurion-zarr-demo` — two deterministic fixed slices from Zarr v2 arrays.
- `tellurion-3d-demo` — synthetic footprint extrusion and 3D Tiles 1.1.

No write route is configured. Images run as UID/GID `10001`, accept Render's
dynamic `PORT`, and verify published SHA-256 manifests before installing or
building Tellurion.

## Reproducibility and licences

The containers use the exact public Tellurion 0.3.0 distribution. Release
archives carry their own BUSL-1.1 terms, while this demo repository is AGPL-3.0.
OpenStreetMap and ESA WorldCover retain their respective data licences and
attribution requirements. See [NOTICE.md](NOTICE.md) before reuse.

The Zarr and 3D datasets are generated locally from short, dependency-free
Python scripts. They are explicitly synthetic and deterministic.

The Zarr viewer demonstrates two configured fixed slices. It does not claim on-the-wire dimension selection; that remains outside this demo's evidence.

Deployment entry points are `Dockerfile` for vector, `Dockerfile.raster` for
COG, `Dockerfile-zarr` for Zarr and `Dockerfile-3d` for 3D Tiles. The complete
four-service definition is in `render.yaml`.

Run the deployment contract checks:

```sh
sh tests/render_deployment_contract.sh
sh tests/render_raster_contract.sh
sh tests/render_zarr_contract.sh
sh tests/render_3d_contract.sh
```

## Related work

- [Tellurion](https://github.com/ccancellieri/tellurion) — the serving engine.
- [Tellurion Italy field case](https://github.com/ccancellieri/tellurion-italy-demo) — reproducible OSM/WorldCover analysis and scoped benchmarks.
- [GeoID](https://github.com/un-fao/GeoID) — earlier multi-tenant OGC/STAC platform work.
- [Carlo Cancellieri's portfolio](https://ccancellieri.github.io/) and [LinkedIn](https://www.linkedin.com/in/ccancellieri/).

Built by Carlo Cancellieri, a geospatial platform engineer and former GeoServer
core developer, with a focus on open standards, interoperable APIs, and
high-performance spatial data systems.
