#!/bin/bash

WORKING_DIR_DATABASE="$1"

DATABASE_USER_DATABASE="$2"

DATABASE_USER_PASSWORD_DATABASE="$3"

DATABASE_NAME_DATABASE="$4"

DATABASE_HOST_DATABASE="$5"

DATABASE_PORT_DATABASE="$6"

# Password support
create_password() {
    cat > $WORKING_DIR_DATABASE/database/import-external/.pgpass << EOF1
$DATABASE_HOST_DATABASE:$DATABASE_PORT_DATABASE:$DATABASE_NAME_DATABASE:$DATABASE_USER_DATABASE:$DATABASE_USER_PASSWORD_DATABASE
EOF1

    chmod 0600 $WORKING_DIR_DATABASE/database/import-external/.pgpass

    export PGPASSFILE=$WORKING_DIR_DATABASE/database/import-external/.pgpass
}

# Downloads
downloads() {
    wget -P $WORKING_DIR_DATABASE/database/import-external http://data.openstreetmapdata.com/water-polygons-split-3857.zip
    unzip -oj $WORKING_DIR_DATABASE/database/import-external/water-polygons-split-3857.zip -d $WORKING_DIR_DATABASE/database/import-external
    rm $WORKING_DIR_DATABASE/database/import-external/water-polygons-split-3857.zip

    wget -P $WORKING_DIR_DATABASE/database/import-external http://data.openstreetmapdata.com/simplified-water-polygons-complete-3857.zip
    unzip -oj $WORKING_DIR_DATABASE/database/import-external/simplified-water-polygons-complete-3857.zip -d $WORKING_DIR_DATABASE/database/import-external
    rm $WORKING_DIR_DATABASE/database/import-external/simplified-water-polygons-complete-3857.zip

    wget -P $WORKING_DIR_DATABASE/database/import-external http://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip
    unzip -oj $WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite.zip -d $WORKING_DIR_DATABASE/database/import-external
    rm $WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite.zip
}

# Drop table natural earth
drop_table_natural_earth() {
    local TABLE_NAME="$1"
    echo "DROP TABLE $TABLE_NAME;" | sqlite3 "$WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite"
    echo "DELETE FROM geometry_columns WHERE f_table_name = '$TABLE_NAME';" \
         | sqlite3 "$WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite"
}

# Clean natural earth
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

    echo "VACUUM;" | sqlite3 "$WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite"
}

# Import natural earth
import_natural_earth() {
    PGCLIENTENCODING=LATIN1 ogr2ogr \
        -progress \
        -f Postgresql \
        -s_srs EPSG:4326 \
        -t_srs EPSG:3857 \
        -clipsrc -180.1 -85.0511 180.1 85.0511 \
        PG:"dbname=$DATABASE_NAME_DATABASE user=$DATABASE_USER_DATABASE host=$DATABASE_HOST_DATABASE password=$DATABASE_USER_PASSWORD_DATABASE port=$DATABASE_PORT_DATABASE" \
        -lco GEOMETRY_NAME=geom \
        -lco DIM=2 \
        -nlt GEOMETRY \
        -overwrite \
        "$WORKING_DIR_DATABASE/database/import-external/natural_earth_vector.sqlite"
}

# Exec psql
exec_psql() {
    psql --host="$DATABASE_HOST_DATABASE" --port=$DATABASE_PORT_DATABASE --dbname="$DATABASE_NAME_DATABASE" --username="$DATABASE_USER_DATABASE"
}

# Exec sql file
exec_sql_file() {
    local SQL_FILE=$1
    cat "$SQL_FILE" | exec_psql
}

# Drop table
drop_table() {
    local TABLE=$1
    local DROP_COMMAND="DROP TABLE IF EXISTS $TABLE;"
    echo $DROP_COMMAND | exec_psql
}

# Hide insert
hide_inserts() {
    grep -v "INSERT 0 1"
}

# Import shapefile
import_shp() {
    local SHP_FILE=$1
    local TABLE_NAME=$2
    shp2pgsql -s 3857 -I -g geometry "$SHP_FILE" "$TABLE_NAME" | exec_psql | hide_inserts
}

# Import water
import_water() {
    local TABLE_NAME="osm_ocean_polygon"
    local SIMPLIFIED_TABLE_NAME="osm_ocean_polygon_gen0"

    drop_table "$TABLE_NAME"
    import_shp "$WORKING_DIR_DATABASE/database/import-external/water_polygons.shp" "$TABLE_NAME"

    drop_table "$SIMPLIFIED_TABLE_NAME"
    import_shp "$WORKING_DIR_DATABASE/database/import-external/simplified_water_polygons.shp" "$SIMPLIFIED_TABLE_NAME"
}

# Copy files from repository
copy_files() {
    cp ./database/import-external/labels/countries.geojson $WORKING_DIR_DATABASE/database/import-external
    cp ./database/import-external/labels/states.geojson $WORKING_DIR_DATABASE/database/import-external
    cp ./database/import-external/labels/seas.geojson $WORKING_DIR_DATABASE/database/import-external
}

# Import geoJSON
import_geojson() {
    local GEOJSON_FILE=$1
    local TABLE_NAME=$2

    drop_table "$TABLE_NAME"
    echo "$GEOJSON_FILE"

    PGCLIENTENCODING=UTF8 ogr2ogr \
        -f Postgresql \
        -s_srs EPSG:4326 \
        -t_srs EPSG:3857 \
        PG:"dbname=$DATABASE_NAME_DATABASE user=$DATABASE_USER_DATABASE host=$DATABASE_HOST_DATABASE password=$DATABASE_USER_PASSWORD_DATABASE port=$DATABASE_PORT_DATABASE" \
        "$GEOJSON_FILE" \
        -nln "$TABLE_NAME"
}

# Import labels
import_labels() {
    echo "Inserting labels into $OSM_DB"

    import_geojson "$WORKING_DIR_DATABASE/database/import-external/seas.geojson" "custom_seas"
    import_geojson "$WORKING_DIR_DATABASE/database/import-external/states.geojson" "custom_states"
    import_geojson "$WORKING_DIR_DATABASE/database/import-external/countries.geojson" "custom_countries"
}

# Password support
remove_password() {
    rm $WORKING_DIR_DATABASE/database/import-external/.pgpass
}

main() {
    create_password
    downloads
    clean_natural_earth
    import_natural_earth
    import_water
    copy_files
    import_labels
    remove_password
}
main