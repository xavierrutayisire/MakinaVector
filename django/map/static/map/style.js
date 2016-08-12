// Ajax request to get the style file
var xhr = new XMLHttpRequest();
xhr.open('GET', 'http://' + window.vtParameters.djangoHost + ':' + window.vtParameters.djangoPort + '/style');
xhr.send(null);
xhr.onreadystatechange = function() {
    var DONE = 4;
    var OK = 200;
    if (xhr.readyState === DONE) {
        if (xhr.status === OK) {
            jsonStyle = JSON.parse(xhr.responseText);

            var layerList = document.getElementById('c-menu--slide-right');
            var inputs = layerList.getElementsByTagName('input');

            allLayers = jsonStyle.layers;
            allLayersId = [];
            allLayersSources = [];

            // Recovery of all the layers id and source-layer
            for (var i = 1; i < allLayers.length; i++) {
                allLayersId[i] = allLayers[i]['id'];
                allLayersSources[i] = allLayers[i]['source-layer'];
            }

            allLayersSourcesAndId = [[]];
            nameLayersSources = [];

            // Add into one list for each source-layer all the id of it
            // Add the name of all the source-layer into one list
            for (var i = 0; i < allLayersId.length; i++) {
                if (typeof allLayersSourcesAndId[allLayersSources[i]] == 'undefined') {
                    nameLayersSources.push(allLayersSources[i]);
                    allLayersSourcesAndId[allLayersSources[i]] = [allLayersId[i]];
                } else {
                    allLayersSourcesAndId[allLayersSources[i]].push(allLayersId[i]);
                }
            }

            // Ajax request for the multiple-style file
            xhrMultipleStyle = new XMLHttpRequest();
            xhrMultipleStyle.open('GET', 'http://' + window.vtParameters.djangoHost + ':' + window.vtParameters.djangoPort + '/multiple-style');
            xhrMultipleStyle.send(null);
            xhrMultipleStyle.onreadystatechange = function() {
                var DONEMultipleStyle = 4;
                var OKMultipleStyle = 200;
                if (xhrMultipleStyle.readyState === DONEMultipleStyle) {
                    if (xhrMultipleStyle.status === OKMultipleStyle) {
                        jsonMultipleStyle = JSON.parse(xhrMultipleStyle.responseText);
                        // Add the other style only if 'multiple_style' is true
                        if (jsonMultipleStyle.multiple_style === true) {
                            map.on('load', function() {
                                // Add of all sources
                                for (var i = 0; i < Object.keys(jsonMultipleStyle.sources).length; i++) {
                                    map.addSource(Object.keys(jsonMultipleStyle.sources)[i], {
                                        type: jsonMultipleStyle.sources[Object.keys(jsonMultipleStyle.sources)[i]]["type"],
                                        tiles: jsonMultipleStyle.sources[Object.keys(jsonMultipleStyle.sources)[i]]["tiles"],
                                        maxzoom: jsonMultipleStyle.sources[Object.keys(jsonMultipleStyle.sources)[i]]["maxzoom"],
                                        minzoom: jsonMultipleStyle.sources[Object.keys(jsonMultipleStyle.sources)[i]]["minzoom"]
                                    });
                                }
                                // Add of all layers
                                for (var y of jsonMultipleStyle.layers) {
                                    var newObject = {};
                                    for (var z of Object.keys(y)) {
                                        if (z !== "before") newObject[z] = y[z];
                                    }

                                    map.addLayer(newObject, y['before']);

                                    // Add into one list for each source-layer all the id of it
                                    // Add the name of all the source-layer into one list
                                    if (typeof y['source-layer'] != 'undefined') {
                                        if (typeof allLayersSourcesAndId[y['source-layer']] == 'undefined') {
                                            nameLayersSources.push(y['source-layer']);
                                            allLayersSourcesAndId[y['source-layer']] = [y['id']];
                                        } else {
                                            allLayersSourcesAndId[y['source-layer']].push(y['id']);
                                        }
                                    }
                                }
                            });
                        }
                    }
                }
            }

            for (var i = 0; i < inputs.length; i++) {
                // When you click on a checkbox
                inputs[i].onclick = function(e) {
                    var id = e.path[0].id;
                    idList = [];

                    // If its not the all checkbox
                    if (id != 'all') {
                        idList = allLayersSourcesAndId[id];
                        if (inputs[0].checked == true) {
                            inputs[0].checked = false;
                        }
                        nbInputChecked = 0;
                        for (var w = 1; w < nameLayersSources.length; w++) {
                            if (inputs[w].checked == true) {
                                nbInputChecked++;
                            }
                        }
                        if (nbInputChecked == nameLayersSources.length - 1) {
                            inputs[0].checked = true;
                        }
                    } else {
                        for (var y = 1; y < nameLayersSources.length; y++) {
                            for (var z = 0; z < allLayersSourcesAndId[nameLayersSources[y]].length; z++) {
                                idList.push(allLayersSourcesAndId[nameLayersSources[y]][z]);
                            }
                            if (inputs[0].checked == false) {
                                inputs[y].checked = false;
                            } else {
                                inputs[y].checked = true;
                            }
                        }
                    }

                    // To change the visibility of the layer
                    idList.forEach(function(id2) {
                        var visibility = map.getLayoutProperty(id2, 'visibility');

                        if (id != 'all') {
                            if (visibility === 'none') {
                                this.className = 'active';
                                map.setLayoutProperty(id2, 'visibility', 'visible');
                            } else {
                                map.setLayoutProperty(id2, 'visibility', 'none');
                                this.className = '';
                            }
                        } else {
                            if (inputs[0].checked == false) {
                                map.setLayoutProperty(id2, 'visibility', 'none');
                                this.className = '';
                            } else {
                                this.className = 'active';
                                map.setLayoutProperty(id2, 'visibility', 'visible');
                            }
                        }

                    });
                };
            }
        }
    }
};