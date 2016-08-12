// Creation of the Mapbox map
mapboxgl.accessToken = window.vtParameters.mapboxAccessToken;
var map = new mapboxgl.Map({
    container: 'map', // container id
    style: 'style',
    center: window.vtParameters.startingPosition, // starting position
    zoom: window.vtParameters.startingZoom // starting zoom
});

// Add the navigations controls
map.addControl(new mapboxgl.Navigation({position: 'top-left'}));