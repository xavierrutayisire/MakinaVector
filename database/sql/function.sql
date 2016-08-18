-- Functions from https://github.com/mapbox/postgis-vt-util
-- LineLabel()
-- MercLength()
-- LabelGrid()
-- ToPoint()

create or replace function LineLabel (
        zoom numeric,
        label text,
        g geometry
    )
    returns boolean
    language plpgsql immutable as
$func$
begin
    if zoom > 20 or ST_Length(g) = 0 then
        -- if length is 0 geom is (probably) a point; keep it
        return true;
    else
        return length(label) between 1 and ST_Length(g)/(2^(20-zoom));
    end if;
end;
$func$;

create or replace function MercLength (g geometry)
    returns numeric
    language plpgsql immutable as
$func$
begin
    return ST_Length(g) * cos(radians(ST_Y(ST_Transform(ST_Centroid(g),4326))));
end;
$func$;

create or replace function LabelGrid (
        g geometry,
        grid_size numeric
    )
    returns text
    language plpgsql immutable as
$func$
begin
    if grid_size <= 0 then
        return 'null';
    end if;
    if GeometryType(g) <> 'POINT' then
        g := (select (ST_DumpPoints(g)).geom limit 1);
    end if;
    return ST_AsText(ST_SnapToGrid(
        g,
        grid_size/2,  -- x origin
        grid_size/2,  -- y origin
        grid_size,    -- x size
        grid_size     -- y size
    ));
end;
$func$;

create or replace function ToPoint (g geometry)
    returns geometry(point)
    language plpgsql immutable as
$func$
begin
    g := ST_MakeValid(g);
    if GeometryType(g) = 'POINT' then
        return g;
    elsif ST_IsEmpty(g) then
        -- This should not be necessary with Geos >= 3.3.7, but we're getting
        -- mystery MultiPoint objects from ST_MakeValid (or somewhere) when
        -- empty objects are input.
        return null;
    else
        return ST_PointOnSurface(g);
    end if;
end;
$func$;

-- OSM ID transformations
-- osm_ids2mbid()

CREATE OR REPLACE FUNCTION osm_ids2mbid (osm_ids BIGINT, is_polygon bool ) RETURNS BIGINT AS $$
BEGIN
 RETURN CASE
   WHEN                      (osm_ids >=     0 )                    THEN (      osm_ids         * 10)       -- +0 point
   WHEN (NOT is_polygon) AND (osm_ids >= -1e17 ) AND (osm_ids < 0 ) THEN ( (abs(osm_ids)      ) * 10) + 1   -- +1 way linestring
   WHEN (    is_polygon) AND (osm_ids >= -1e17 ) AND (osm_ids < 0 ) THEN ( (abs(osm_ids)      ) * 10) + 2   -- +2 way poly
   WHEN (NOT is_polygon) AND (osm_ids <  -1e17 )                    THEN ( (abs(osm_ids) -1e17) * 10) + 3   -- +3 relations linestring
   WHEN (    is_polygon) AND (osm_ids <  -1e17 )                    THEN ( (abs(osm_ids) -1e17) * 10) + 4   -- +4 relations poly
   ELSE 0
 END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Polygon
-- is_polygon()

CREATE OR REPLACE FUNCTION is_polygon( geom geometry) RETURNS bool AS $$
BEGIN
    RETURN ST_GeometryType(geom) IN ('ST_Polygon', 'ST_MultiPolygon');
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Building
-- building_is_underground()

CREATE OR REPLACE FUNCTION building_is_underground(level INTEGER) RETURNS VARCHAR
AS $$
BEGIN
    IF level >= 1 THEN
        RETURN 'true';
    ELSE
        RETURN 'false';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Landuse_overlay
-- is_landuse_overlay()
-- landuse_overlay_class()

CREATE OR REPLACE FUNCTION is_landuse_overlay(type TEXT)
RETURNS BOOLEAN AS $$
BEGIN
	RETURN type IN ('wetland', 'marsh', 'swamp', 'bog', 'mud', 'tidalflat', 'national_park', 'nature_reserve', 'protected_area');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION landuse_overlay_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('national_park','nature_reserve','protected_area') THEN 'national_park'
            WHEN type IN ('mud','tidalflat') THEN 'wetland_noveg'
            WHEN type IN ('wetland','marsh','swamp','bog') THEN 'wetland'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Road
-- road_type_class()
-- road_structure()
-- road_class()
-- road_localrank()
-- road_type()
-- road_type_value()
-- road_oneway()

CREATE OR REPLACE FUNCTION road_type_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('track') THEN 'track'
            WHEN type IN ('trunk_link','primary_link','secondary_link','tertiary_link') THEN 'link'
            WHEN type IN ('motorway_link') THEN 'motorway_link'
            WHEN type IN ('primary') THEN 'primary'
            WHEN type IN ('secondary') THEN 'secondary'
            WHEN type IN ('tertiary') THEN 'tertiary'
            WHEN type IN ('service') THEN 'service'
            WHEN type IN ('rail','light_rail','subway') THEN 'major_rail'
            WHEN type IN ('unclassified','residential','road','living_street','raceway') THEN 'street'
            WHEN type IN ('ferry') THEN 'ferry'
            WHEN type IN ('hole') THEN 'golf'
            WHEN type IN ('motorway') THEN 'motorway'
            WHEN type IN ('steps','corridor','crossing','piste','mtb','hiking','cycleway','footway','path','bridleway') THEN 'path'
            WHEN type IN ('cable_car','gondola','mixed_lift','chair_lift','drag_lift','t-bar','j-bar','platter','rope_tow','zip_line','magic_carpet','canopy') THEN 'aerialway'
            WHEN type IN ('construction') THEN 'construction'
            WHEN type IN ('trunk') THEN 'trunk'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION road_structure(is_tunnel BOOLEAN, is_bridge BOOLEAN, is_ford BOOLEAN) RETURNS VARCHAR
AS $$
BEGIN
    IF is_tunnel THEN
        RETURN 'tunnel';
    ELSIF is_bridge THEN
        RETURN 'bridge';
    ELSIF is_ford THEN
        RETURN 'ford';
    ELSE
        RETURN 'none';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION road_class(type VARCHAR, service VARCHAR, access VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN CASE
        WHEN road_type_class(type) = 'major_rail' AND service IN ('yard', 'siding', 'spur', 'crossover') THEN 'minor_rail'
        WHEN road_type_class(type) = 'street' AND access IN ('no', 'private') THEN 'street_limited'
        ELSE road_type_class(type)
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION road_localrank(type VARCHAR) RETURNS INTEGER
AS $$
BEGIN
    RETURN CASE
        WHEN type IN ('motorway') THEN 10
        WHEN type IN ('trunk') THEN 20
        WHEN type IN ('primary') THEN 30
        WHEN type IN ('secondary') THEN 40
        WHEN type IN ('tertiary') THEN 50
        ELSE 100
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION road_type(class VARCHAR, type VARCHAR, construction VARCHAR, tracktype VARCHAR, service VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN CASE
        WHEN class = 'construction' THEN road_type_value(class, construction)
        WHEN class = 'track' THEN road_type_value(class, tracktype)
        WHEN class = 'service' THEN road_type_value(class, service)
        WHEN class = 'golf' THEN 'golf'
        WHEN class = 'mtb' THEN 'mountain_bike'
        WHEN class = 'aerialway' AND type IN ('gondola', 'mixed_lift', 'chair_lift') THEN road_type_value(class, type)
        WHEN class = 'aerialway' AND type = 'cable_car' THEN 'aerialway:cablecar'
        WHEN class = 'aerialway' AND type IN ('drag_lift', 't-bar', 'j-bar', 'platter', 'rope_tow', 'zip_line') THEN 'aerialway:drag_lift'
        WHEN class = 'aerialway' AND type IN ('magic_carpet', 'canopy') THEN 'aerialway:magic_carpet'
        ELSE type
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION road_type_value(left_value VARCHAR, right_value VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    IF right_value = '' OR right_value IS NULL THEN
        RETURN left_value;
    ELSE
        RETURN left_value || ':' || right_value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION road_oneway(oneway INTEGER) RETURNS VARCHAR
AS $$
BEGIN
    IF oneway = 1 THEN
        RETURN 'true';
    ELSE
        RETURN 'false';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Landuse
-- landuse_class()

CREATE OR REPLACE FUNCTION landuse_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('salt_pond') THEN 'salt_pond'
            WHEN type IN ('military') THEN 'military'
            WHEN type IN ('grass','grassland','meadow','heath','fell') THEN 'grass'
            WHEN type IN ('athletics','chess','pitch') THEN 'pitch'
            WHEN type IN ('retail') THEN 'retail'
            WHEN type IN ('residential') THEN 'residential'
            WHEN type IN ('winter_sports') THEN 'winter_sports'
            WHEN type IN ('orchard','farm','farmland','farmyard','allotments','vineyard','plant_nursery') THEN 'agriculture'
            WHEN type IN ('scrub') THEN 'scrub'
            WHEN type IN ('commercial') THEN 'commercial'
            WHEN type IN ('aboriginal_lands') THEN 'aboriginal_lands'
            WHEN type IN ('wood','forest') THEN 'wood'
            WHEN type IN ('railway') THEN 'railway'
            WHEN type IN ('industrial') THEN 'industrial'
            WHEN type IN ('cemetery','christian','jewish') THEN 'cemetery'
            WHEN type IN ('glacier') THEN 'glacier'
            WHEN type IN ('park','dog_park','common','garden','golf_course','playground','recreation_ground','village_green','zoo','sports_centre','camp_site') THEN 'park'
            WHEN type IN ('greenfield') THEN 'greenfield'
            WHEN type IN ('school','college','university') THEN 'school'
            WHEN type IN ('hospital') THEN 'hospital'
            WHEN type IN ('rock','bare_rock','scree','quarry') THEN 'rock'
            WHEN type IN ('landfill') THEN 'landfill'
            WHEN type IN ('sand','beach') THEN 'sand'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Barrier line
-- barrier_line_class()

CREATE OR REPLACE FUNCTION barrier_line_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('cliff','earth_bank') THEN 'cliff'
            WHEN type IN ('gate','entrance','spikes','bollard','lift_gate','kissing_gate','stile') THEN 'gate'
            WHEN type IN ('city_wall','fence','retaining_wall','wall','wire_fence','True','embankment','cable_barrier','jersey_barrier') THEN 'fence'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Maki label
-- maki_label_class()

CREATE OR REPLACE FUNCTION maki_label_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('accessories','antiques','art','beauty','bed','boutique','camera','carpet','charity','chemist','chocolate','coffee','computer','confectionery','convenience','copyshop','cosmetics','garden_centre','doityourself','erotic','electronics','fabric','florist','furniture','video_games','video','general','gift','hardware','hearing_aids','hifi','ice_cream','interior_decoration','jewelry','kiosk','lamps','mall','massage','motorcycle','mobile_phone','newsagent','optician','outdoor','perfumery','perfume','pet','photo','second_hand','shoes','sports','stationery','tailor','tattoo','ticket','tobacco','toys','travel_agency','watches','weapons','wholesale') THEN 'shop'
            WHEN type IN ('toilets') THEN 'toilet'
            WHEN type IN ('bicycle') THEN 'bicycle'
            WHEN type IN ('cinema') THEN 'cinema'
            WHEN type IN ('helipad') THEN 'heliport'
            WHEN type IN ('camp_site','caravan_site') THEN 'campsite'
            WHEN type IN ('dog_park') THEN 'dog-park'
            WHEN type IN ('cricket') THEN 'cricket'
            WHEN type IN ('books','library') THEN 'library'
            WHEN type IN ('embassy') THEN 'embassy'
            WHEN type IN ('university','college') THEN 'college'
            WHEN type IN ('hotel','motel','bed_and_breakfast','guest_house','hostel','chalet','alpine_hut','camp_site') THEN 'lodging'
            WHEN type IN ('chocolate','confectionery') THEN 'ice-cream'
            WHEN type IN ('cafe') THEN 'cafe'
            WHEN type IN ('golf','golf_course','miniature_golf') THEN 'golf'
            WHEN type IN ('bicycle_rental') THEN 'bicycle-share'
            WHEN type IN ('alcohol','beverages','wine') THEN 'alcohol-shop'
            WHEN type IN ('police') THEN 'police'
            WHEN type IN ('butcher') THEN 'slaughterhouse'
            WHEN type IN ('bag','clothes') THEN 'clothing-store'
            WHEN type IN ('veterinary') THEN 'veterinary'
            WHEN type IN ('grave_yard','cemetery') THEN 'cemetery'
            WHEN type IN ('theme_park') THEN 'amusement-park'
            WHEN type IN ('pharmacy') THEN 'pharmacy'
            WHEN type IN ('station') THEN 'airfield'
            WHEN type IN ('attraction','viewpoint') THEN 'attraction'
            WHEN type IN ('biergarten','pub') THEN 'beer'
            WHEN type IN ('music','musical_instrument') THEN 'music'
            WHEN type IN ('playground') THEN 'playground'
            WHEN type IN ('american_football','stadium','soccer','pitch') THEN 'stadium'
            WHEN type IN ('prison') THEN 'prison'
            WHEN type IN ('fuel') THEN 'fuel'
            WHEN type IN ('accessories','antiques','art','artwork','gallery','arts_centre') THEN 'art-gallery'
            WHEN type IN ('townhall','public_building','courthouse','community_centre') THEN 'town-hall'
            WHEN type IN ('subway_entrance') THEN 'entrance'
            WHEN type IN ('laundry','dry_cleaning') THEN 'laundry'
            WHEN type IN ('garden') THEN 'garden'
            WHEN type IN ('fast_food','food_court') THEN 'fast-food'
            WHEN type IN ('information') THEN 'information'
            WHEN type IN ('bus_stop','bus_station') THEN 'bus'
            WHEN type IN ('park','bbq') THEN 'park'
            WHEN type IN ('supermarket','deli','delicatessen','department_store','greengrocer','marketplace') THEN 'grocery'
            WHEN type IN ('dentist') THEN 'dentist'
            WHEN type IN ('fire_station') THEN 'fire-station'
            WHEN type IN ('bar','nightclub') THEN 'bar'
            WHEN type IN ('post_box','post_office') THEN 'post'
            WHEN type IN ('bank') THEN 'bank'
            WHEN type IN ('school','kindergarten') THEN 'school'
            WHEN type IN ('theater') THEN 'theater'
            WHEN type IN ('zoo') THEN 'zoo'
            WHEN type IN ('restaurant') THEN 'restaurant'
            WHEN type IN ('marina','dock') THEN 'harbor'
            WHEN type IN ('car','car_repair','taxi') THEN 'car'
            WHEN type IN ('doctor') THEN 'doctor'
            WHEN type IN ('bakery') THEN 'bakery'
            WHEN type IN ('place_of_worship') THEN 'place-of-worship'
            WHEN type IN ('picnic-site') THEN 'picnic-site'
            WHEN type IN ('monument') THEN 'monument'
            WHEN type IN ('ferry_terminal') THEN 'ferry'
            WHEN type IN ('hospital','nursing_home') THEN 'hospital'
            WHEN type IN ('museum') THEN 'museum'
            WHEN type IN ('swimming_area','swimming') THEN 'swimming'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Place label
-- normalize_scalerank()

CREATE OR REPLACE FUNCTION normalize_scalerank(scalerank INTEGER) RETURNS INTEGER
AS $$
BEGIN
    RETURN CASE
        WHEN scalerank >= 9 THEN 9
        ELSE scalerank
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Poi label
-- poi_label_localrank()
-- poi_label_scalerank()
-- format_type()

CREATE OR REPLACE FUNCTION poi_label_localrank(type VARCHAR, name VARCHAR) RETURNS INTEGER
AS $$
BEGIN
    RETURN CASE
        -- Nameless POIs should have the maximal localrank and least priority
        WHEN name = '' THEN 2000
        WHEN type IN ('station', 'subway_entrance', 'park', 'cemetery', 'bank', 'supermarket', 'car', 'library', 'university', 'college', 'police', 'townhall', 'courthouse') THEN 2
        WHEN type IN ('nature_reserve', 'garden', 'public_building') THEN 3
        WHEN type IN ('stadium') THEN 90
        WHEN type IN ('hospital') THEN 100
        WHEN type IN ('zoo') THEN 200
        WHEN type IN ('university', 'school', 'college', 'kindergarten') THEN 300
        WHEN type IN ('supermarket', 'department_store') THEN 400
        WHEN type IN ('nature_reserve', 'swimming_area') THEN 500
        WHEN type IN ('attraction') THEN 600
        ELSE 1000
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION poi_label_scalerank(type VARCHAR, area REAL) RETURNS INTEGER
AS $$
BEGIN
    RETURN CASE
        WHEN area > 145000 THEN 1
        WHEN area > 12780 THEN 2
        WHEN area > 2960 THEN 3
        WHEN type IN ('station') THEN 1
        ELSE 4
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION format_type(class VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN REPLACE(INITCAP(class), '_', ' ');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Motorway junction
-- junction_type()

CREATE OR REPLACE FUNCTION junction_type(type VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN CASE
        WHEN type = 'motorway_junction' THEN 'motorway'
        ELSE type
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Airport label
-- airport_label_scalerank()
-- airport_label_class()

CREATE OR REPLACE FUNCTION airport_label_scalerank(maki VARCHAR, area REAL, aerodrome VARCHAR) RETURNS INTEGER
AS $$
BEGIN
    RETURN CASE
        WHEN (maki = 'airport' AND area >= 300000) OR aerodrome = 'international' THEN 1
        WHEN maki = 'airport' AND area < 300000 THEN 2
        WHEN maki = 'airfield' AND area >= 145000 THEN 3
        WHEN maki = 'airfield' AND area < 145000 THEN 4
        ELSE 4
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION airport_label_class(kind VARCHAR, type VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN CASE
        WHEN kind = 'heliport' THEN 'heliport'
        WHEN kind = 'aerodrome' AND type IN ('public', 'Public') THEN 'airport'
        WHEN kind = 'aerodrome' AND type IN ('private', 'Private', 'military/public', 'Military/Public') THEN 'airfield'
        ELSE 'airfield'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Rail station
-- rail_station_class()

CREATE OR REPLACE FUNCTION rail_station_class(type VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE
            WHEN type IN ('light_rail','halt') THEN 'rail-light'
            WHEN type IN ('stop','subway','tram_stop') THEN 'rail-metro'
            WHEN type IN ('station') THEN 'rail'
            WHEN type IN ('subway_entrance') THEN 'entrance'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Mountain peak
-- meter_to_feet()
-- mountain_peak_type()

CREATE OR REPLACE FUNCTION meter_to_feet(meter INTEGER) RETURNS INTEGER
AS $$
BEGIN
    RETURN round(meter * 3.28084);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION mountain_peak_type(type VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    IF type = 'volcano' THEN
        RETURN type;
    ELSE
        RETURN 'mountain';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add the geometry into diff table for Insert or Update or delete
-- add_diff_I_U()
-- add_diff_D()

CREATE OR REPLACE FUNCTION add_diff_I_U()
  RETURNS trigger AS
$$
BEGIN
    INSERT INTO diff (geometry, processed)
    VALUES(new.geometry, false);
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_diff_D()
  RETURNS trigger AS
$$
BEGIN
    INSERT INTO diff (geometry, processed)
    VALUES(old.geometry, false);
    RETURN old;
END;
$$ LANGUAGE plpgsql;
