-- Create Table, Index and analyse
-- osm_landuse_polygon_subdivided_gen0
-- osm_landuse_polygon_subdivided_gen1
-- osm_landuse_polygon_subdivided

DROP TABLE IF EXISTS osm_landuse_polygon_subdivided_gen0 CASCADE;
DROP TABLE IF EXISTS osm_landuse_polygon_subdivided_gen1 CASCADE;
DROP TABLE IF EXISTS osm_landuse_polygon_subdivided CASCADE;

CREATE TABLE osm_landuse_polygon_subdivided_gen0 AS SELECT id,type,area,st_subdivide(geometry,1024) AS geometry FROM osm_landuse_polygon_gen0;
CREATE TABLE osm_landuse_polygon_subdivided_gen1 AS SELECT id,type,area,st_subdivide(geometry,1024) AS geometry FROM osm_landuse_polygon_gen1;
CREATE TABLE osm_landuse_polygon_subdivided AS SELECT id,type,area,st_subdivide(geometry,1024) AS geometry FROM osm_landuse_polygon;

SELECT UpdateGeometrySRID('osm_landuse_polygon_subdivided_gen0','geometry',3857);
SELECT UpdateGeometrySRID('osm_landuse_polygon_subdivided_gen1','geometry',3857);
SELECT UpdateGeometrySRID('osm_landuse_polygon_subdivided','geometry',3857);

CREATE INDEX ON osm_landuse_polygon_subdivided_gen0 USING btree(id);
CREATE INDEX ON osm_landuse_polygon_subdivided_gen1 USING btree(id);
CREATE INDEX ON osm_landuse_polygon_subdivided USING btree(id);

CREATE INDEX ON osm_landuse_polygon_subdivided_gen0 USING btree (st_geohash(st_transform(st_setsrid(box2d(geometry)::geometry, 3857), 4326)));
CREATE INDEX ON osm_landuse_polygon_subdivided_gen1 USING btree (st_geohash(st_transform(st_setsrid(box2d(geometry)::geometry, 3857), 4326)));
CREATE INDEX ON osm_landuse_polygon_subdivided USING btree (st_geohash(st_transform(st_setsrid(box2d(geometry)::geometry, 3857), 4326)));

CREATE INDEX ON osm_landuse_polygon_subdivided_gen0 USING gist (geometry);
CREATE INDEX ON osm_landuse_polygon_subdivided_gen1 USING gist (geometry);
CREATE INDEX ON osm_landuse_polygon_subdivided USING gist (geometry);

ANALYZE osm_landuse_polygon_subdivided_gen0;
ANALYZE osm_landuse_polygon_subdivided_gen1;
ANALYZE osm_landuse_polygon_subdivided;

-- Create Table and Index
-- osm_water_point

DROP TABLE IF EXISTS osm_water_point CASCADE;
CREATE TABLE osm_water_point AS
SELECT id,
       topoint(geometry) AS geometry,
       name, name_fr, name_en, name_de,
       name_es, name_ru, name_zh,
       area
FROM osm_water_polygon;

CREATE INDEX ON osm_water_point USING gist (geometry);
CREATE INDEX ON osm_water_point
USING btree (st_geohash(st_transform(st_setsrid(box2d(geometry)::geometry, 3857), 4326)));

-- Update Table
-- osm_place_point

UPDATE osm_place_point
SET scalerank = improved_places.scalerank
FROM
(
    SELECT osm.id, ne.scalerank
    FROM ne_10m_populated_places AS ne, osm_place_point AS osm
    WHERE
    (
        ne.name ILIKE osm.name OR
        ne.name ILIKE osm.name_en OR
        ne.namealt ILIKE osm.name OR
        ne.namealt ILIKE osm.name_en OR
        ne.meganame ILIKE osm.name OR
        ne.meganame ILIKE osm.name_en OR
        ne.gn_ascii ILIKE osm.name OR
        ne.gn_ascii ILIKE osm.name_en OR
        ne.nameascii ILIKE osm.name OR
        ne.nameascii ILIKE osm.name_en
    )
    AND (osm.type = 'city' OR osm.type = 'town' OR osm.type = 'village')
    AND st_dwithin(ne.geom, osm.geometry, 50000)
    ) AS improved_places
WHERE osm_place_point.id = improved_places.id;

UPDATE osm_place_point
SET geometry = topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

-- Update Table
-- osm_poi_polygon

UPDATE osm_poi_polygon
SET geometry = topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

-- Update Table
-- osm_housenumber_polygon

UPDATE osm_housenumber_polygon
SET geometry = topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

-- Create Index
-- osm_road_geometry_class

DROP INDEX IF EXISTS osm_road_geometry_class;
CREATE INDEX osm_road_geometry_class ON osm_road_geometry(road_class(type, service, access));

-- Create Table for check the diff and generate new tiles
-- diff

DROP TABLE IF EXISTS diff;
CREATE TABLE diff (
    id serial PRIMARY KEY,
    geometry geometry(Geometry,3857) NOT NULL,
    processed boolean NOT NULL
);
