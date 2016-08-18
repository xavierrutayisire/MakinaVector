#!/bin/bash

working_dir_imposm3="$1"

database_user_imposm3="$2"

database_user_password_imposm3="$3"

database_name_imposm3="$4"

database_host_imposm3="$5"

database_port_imposm3="$6"

# Password support
cat > $working_dir_imposm3/imposm3/import-external/.pgpass << EOF1
$database_host_imposm3:$database_port_imposm3:$database_name_imposm3:$database_user_imposm3:$database_user_password_imposm3
EOF1

chmod 0600 $working_dir_imposm3/imposm3/import-external/.pgpass

export PGPASSFILE=$working_dir_imposm3/imposm3/import-external/.pgpass

#### Downloads ####

wget -P $working_dir_imposm3/imposm3/import-external http://data.openstreetmapdata.com/water-polygons-split-3857.zip
unzip -oj $working_dir_imposm3/imposm3/import-external/water-polygons-split-3857.zip -d $working_dir_imposm3/imposm3/import-external
rm $working_dir_imposm3/imposm3/import-external/water-polygons-split-3857.zip

wget -P $working_dir_imposm3/imposm3/import-external http://data.openstreetmapdata.com/simplified-water-polygons-complete-3857.zip
unzip -oj $working_dir_imposm3/imposm3/import-external/simplified-water-polygons-complete-3857.zip -d $working_dir_imposm3/imposm3/import-external
rm $working_dir_imposm3/imposm3/import-external/simplified-water-polygons-complete-3857.zip

wget -P $working_dir_imposm3/imposm3/import-external http://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip
unzip -oj $working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite.zip -d $working_dir_imposm3/imposm3/import-external
rm $working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite.zip

#### Clean natural earth ####

drop_table_natural_earth() {
    local table_name="$1"
    echo "DROP TABLE $table_name;" | sqlite3 "$working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite"
    echo "DELETE FROM geometry_columns WHERE f_table_name = '$table_name';" \
         | sqlite3 "$working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite"
}

clean_natural_earth() {
    drop_table_natural_earth 'ne_10m_admin_0_antarctic_claim_limit_lines'
    drop_table_natural_earth 'ne_10m_admin_0_antarctic_claims'
    drop_table_natural_earth 'ne_10m_admin_0_map_subunits'
    drop_table_natural_earth 'ne_10m_admin_0_map_units'
    drop_table_natural_earth 'ne_10m_admin_0_pacific_groupings'
    drop_table_natural_earth 'ne_10m_admin_0_scale_rank'
    drop_table_natural_earth 'ne_10m_admin_0_scale_rank_minor_islands'
    drop_table_natural_earth 'ne_10m_admin_0_countries_lakes'
    drop_table_natural_earth 'ne_10m_airports'
    drop_table_natural_earth 'ne_10m_geography_marine_polys'
    drop_table_natural_earth 'ne_10m_geography_regions_elevation_points'
    drop_table_natural_earth 'ne_10m_geography_regions_points'
    drop_table_natural_earth 'ne_10m_geography_regions_polys'
    drop_table_natural_earth 'ne_10m_glaciated_areas'
    drop_table_natural_earth 'ne_10m_admin_0_boundary_lines_map_units'
    drop_table_natural_earth 'ne_10m_admin_0_boundary_lines_maritime_indicator'
    drop_table_natural_earth 'ne_10m_admin_0_countries'
    drop_table_natural_earth 'ne_10m_admin_0_label_points'
    drop_table_natural_earth 'ne_10m_antarctic_ice_shelves_lines'
    drop_table_natural_earth 'ne_10m_antarctic_ice_shelves_polys'
    drop_table_natural_earth 'ne_10m_coastline'
    drop_table_natural_earth 'ne_10m_geographic_lines'
    drop_table_natural_earth 'ne_10m_lakes_europe'
    drop_table_natural_earth 'ne_10m_lakes_historic'
    drop_table_natural_earth 'ne_10m_lakes_north_america'
    drop_table_natural_earth 'ne_10m_lakes_pluvial'
    drop_table_natural_earth 'ne_10m_land_ocean_label_points'
    drop_table_natural_earth 'ne_10m_land_ocean_seams'
    drop_table_natural_earth 'ne_10m_land_scale_rank'
    drop_table_natural_earth 'ne_10m_minor_islands'
    drop_table_natural_earth 'ne_10m_minor_islands_coastline'
    drop_table_natural_earth 'ne_10m_minor_islands_label_points'
    drop_table_natural_earth 'ne_10m_parks_and_protected_lands_area'
    drop_table_natural_earth 'ne_10m_parks_and_protected_lands_line'
    drop_table_natural_earth 'ne_10m_parks_and_protected_lands_point'
    drop_table_natural_earth 'ne_10m_parks_and_protected_lands_scale_rank'
    drop_table_natural_earth 'ne_10m_playas'
    drop_table_natural_earth 'ne_10m_populated_places_simple'
    drop_table_natural_earth 'ne_10m_ports'
    drop_table_natural_earth 'ne_10m_railroads'
    drop_table_natural_earth 'ne_10m_railroads_north_america'
    drop_table_natural_earth 'ne_10m_reefs'
    drop_table_natural_earth 'ne_10m_rivers_europe'
    drop_table_natural_earth 'ne_10m_rivers_lake_centerlines'
    drop_table_natural_earth 'ne_10m_rivers_lake_centerlines_scale_rank'
    drop_table_natural_earth 'ne_10m_rivers_north_america'
    drop_table_natural_earth 'ne_10m_roads'
    drop_table_natural_earth 'ne_10m_roads_north_america'
    drop_table_natural_earth 'ne_10m_time_zones'
    drop_table_natural_earth 'ne_10m_urban_areas'
    drop_table_natural_earth 'ne_10m_urban_areas_landscan'
    drop_table_natural_earth 'ne_10m_admin_1_states_provinces_lakes_shp'
    drop_table_natural_earth 'ne_10m_admin_1_states_provinces_shp'
    drop_table_natural_earth 'ne_50m_admin_0_boundary_lines_disputed_areas'
    drop_table_natural_earth 'ne_50m_admin_1_states_provinces_shp'
    drop_table_natural_earth 'ne_50m_admin_0_countries_lakes'
    drop_table_natural_earth 'ne_50m_admin_0_map_subunits'
    drop_table_natural_earth 'ne_50m_admin_0_map_units'
    drop_table_natural_earth 'ne_50m_admin_0_pacific_groupings'
    drop_table_natural_earth 'ne_50m_admin_0_scale_rank'
    drop_table_natural_earth 'ne_50m_admin_0_sovereignty'
    drop_table_natural_earth 'ne_50m_admin_0_tiny_countries'
    drop_table_natural_earth 'ne_50m_admin_0_tiny_countries_scale_rank'
    drop_table_natural_earth 'ne_50m_geography_marine_polys'
    drop_table_natural_earth 'ne_50m_geography_regions_elevation_points'
    drop_table_natural_earth 'ne_50m_geography_regions_points'
    drop_table_natural_earth 'ne_50m_geography_regions_polys'
    drop_table_natural_earth 'ne_50m_glaciated_areas'
    drop_table_natural_earth 'ne_50m_admin_0_boundary_map_units'
    drop_table_natural_earth 'ne_50m_admin_0_breakaway_disputed_areas'
    drop_table_natural_earth 'ne_50m_admin_0_countries'
    drop_table_natural_earth 'ne_50m_antarctic_ice_shelves_lines'
    drop_table_natural_earth 'ne_50m_antarctic_ice_shelves_polys'
    drop_table_natural_earth 'ne_50m_coastline'
    drop_table_natural_earth 'ne_50m_geographic_lines'
    drop_table_natural_earth 'ne_110m_admin_0_countries_lakes'
    drop_table_natural_earth 'ne_110m_geography_marine_polys'
    drop_table_natural_earth 'ne_110m_geography_regions_elevation_points'
    drop_table_natural_earth 'ne_110m_geography_regions_points'
    drop_table_natural_earth 'ne_110m_geography_regions_polys'
    drop_table_natural_earth 'ne_110m_glaciated_areas'
    drop_table_natural_earth 'ne_110m_admin_0_map_units'
    drop_table_natural_earth 'ne_110m_admin_0_pacific_groupings'
    drop_table_natural_earth 'ne_110m_admin_0_scale_rank'
    drop_table_natural_earth 'ne_10m_admin_0_disputed_areas'
    drop_table_natural_earth 'ne_10m_admin_0_disputed_areas_scale_rank_minor_islands'
    drop_table_natural_earth 'ne_10m_admin_0_seams'
    drop_table_natural_earth 'ne_10m_admin_0_sovereignty'
    drop_table_natural_earth 'ne_10m_admin_1_seams'
    drop_table_natural_earth 'ne_10m_land'
    drop_table_natural_earth 'ne_10m_ocean_scale_rank'
    drop_table_natural_earth 'ne_110m_admin_0_sovereignty'
    drop_table_natural_earth 'ne_110m_admin_0_tiny_countries'
    drop_table_natural_earth 'ne_110m_admin_1_states_provinces_lakes_shp'
    drop_table_natural_earth 'ne_110m_coastline'
    drop_table_natural_earth 'ne_110m_geographic_lines'
    drop_table_natural_earth 'ne_110m_populated_places'
    drop_table_natural_earth 'ne_110m_populated_places_simple'
    drop_table_natural_earth 'ne_110m_rivers_lake_centerlines'
    drop_table_natural_earth 'ne_110m_admin_0_countries'
    drop_table_natural_earth 'ne_110m_admin_1_states_provinces_lines'
    drop_table_natural_earth 'ne_110m_admin_1_states_provinces_shp'
    drop_table_natural_earth 'ne_110m_admin_1_states_provinces_shp_scale_rank'
    drop_table_natural_earth 'ne_110m_land'
    drop_table_natural_earth 'ne_50m_admin_0_boundary_lines_maritime_indicator'
    drop_table_natural_earth 'ne_50m_admin_1_states_provinces_lakes_shp'
    drop_table_natural_earth 'ne_50m_admin_1_states_provinces_shp_scale_rank'
    drop_table_natural_earth 'ne_50m_lakes_historic'
    drop_table_natural_earth 'ne_50m_land'
    drop_table_natural_earth 'ne_50m_playas'
    drop_table_natural_earth 'ne_50m_populated_places'
    drop_table_natural_earth 'ne_50m_populated_places_simple'
    drop_table_natural_earth 'ne_50m_rivers_lake_centerlines'
    drop_table_natural_earth 'ne_50m_rivers_lake_centerlines_scale_rank'
    drop_table_natural_earth 'ne_50m_urban_areas'

    echo "VACUUM;" | sqlite3 "$working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite"
}

clean_natural_earth

#### Import natural earth ####

PGCLIENTENCODING=LATIN1 ogr2ogr \
    -progress \
    -f Postgresql \
    -s_srs EPSG:4326 \
    -t_srs EPSG:3857 \
    -clipsrc -180.1 -85.0511 180.1 85.0511 \
    PG:"dbname=$database_name_imposm3 user=$database_user_imposm3 host=$database_host_imposm3 password=$database_user_password_imposm3 port=$database_port_imposm3" \
    -lco GEOMETRY_NAME=geom \
    -lco DIM=2 \
    -nlt GEOMETRY \
    -overwrite \
    "$working_dir_imposm3/imposm3/import-external/natural_earth_vector.sqlite"

#### Import water ####

exec_psql() {
    psql --host="$database_host_imposm3" --port=$database_port_imposm3 --dbname="$database_name_imposm3" --username="$database_user_imposm3"
}

exec_sql_file() {
    local sql_file=$1
    cat "$sql_file" | exec_psql
}

drop_table() {
    local table=$1
    local drop_command="DROP TABLE IF EXISTS $table;"
    echo $drop_command | exec_psql
}

hide_inserts() {
    grep -v "INSERT 0 1"
}

import_shp() {
    local shp_file=$1
    local table_name=$2
    shp2pgsql -s 3857 -I -g geometry "$shp_file" "$table_name" | exec_psql | hide_inserts
}

import_water() {
    local table_name="osm_ocean_polygon"
    local simplified_table_name="osm_ocean_polygon_gen0"

    drop_table "$table_name"
    import_shp "$working_dir_imposm3/imposm3/import-external/water_polygons.shp" "$table_name"

    drop_table "$simplified_table_name"
    import_shp "$working_dir_imposm3/imposm3/import-external/simplified_water_polygons.shp" "$simplified_table_name"
}

import_water

#### Import labels ####

cp ./database/import-external/labels/countries.geojson $working_dir_imposm3/imposm3/import-external
cp ./database/import-external/labels/states.geojson $working_dir_imposm3/imposm3/import-external
cp ./database/import-external/labels/seas.geojson $working_dir_imposm3/imposm3/import-external

import_geojson() {
    local geojson_file=$1
    local table_name=$2

    drop_table "$table_name"
    echo "$geojson_file"

    PGCLIENTENCODING=UTF8 ogr2ogr \
    -f Postgresql \
    -s_srs EPSG:4326 \
    -t_srs EPSG:3857 \
    PG:"dbname=$database_name_imposm3 user=$database_user_imposm3 host=$database_host_imposm3 password=$database_user_password_imposm3 port=$database_port_imposm3" \
    "$geojson_file" \
    -nln "$table_name"
}

import_labels() {
    echo "Inserting labels into $OSM_DB"

    import_geojson "$working_dir_imposm3/imposm3/import-external/seas.geojson" "custom_seas"
    import_geojson "$working_dir_imposm3/imposm3/import-external/states.geojson" "custom_states"
    import_geojson "$working_dir_imposm3/imposm3/import-external/countries.geojson" "custom_countries"
}

import_labels

# Password support 
rm $working_dir_imposm3/imposm3/import-external/.pgpass
