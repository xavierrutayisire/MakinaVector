// ADD LAYER
var modalAddLayer = document.getElementById('myModalAddLayer');
var btnAddLayer = document.getElementById("myBtnAddLayer");
var spanAddLayer = document.getElementsByClassName("closeAddLayer")[0];
btnAddLayer.onclick = function() {
    modalAddLayer.style.display = "block";
}
spanAddLayer.onclick = function() {
    modalAddLayer.style.display = "none";
}
var optionsAddLayer = {
  dataType: 'xml',
  url: '/add-layer',
  beforeSubmit: showRequestAddLayer,
  success: showResponseAddLayer
}
$('#form_add_layer').submit(function() {
    $(this).ajaxSubmit(optionsAddLayer);

    return false;
});
function showRequestAddLayer(formData, jqForm, optionsAddLayer) {
    return true;
}
function showResponseAddLayer(response) {
    window.location = 'http://' + window.vtParameters.djangoHost + ':' + window.vtParameters.djangoPort;
}

// DELETE LAYER
var modalDelLayer = document.getElementById('myModalDelLayer');
var btnDelLayer = document.getElementById("myBtnDelLayer");
var spanDelLayer = document.getElementsByClassName("closeDelLayer")[0];
btnDelLayer.onclick = function() {
    modalDelLayer.style.display = "block";
}
spanDelLayer.onclick = function() {
    modalDelLayer.style.display = "none";
}
var optionsDelLayer = {
  dataType: 'xml',
  url: '/delete-layer',
  beforeSubmit: showRequestDelLayer,
  statusCode: {
    202: function() {
      showResponseDelLayer(202);
    },
    200: function() {
      showResponseDelLayer(200);
    }
  }
}
$('#form_delete_layer').submit(function() {
    $(this).ajaxSubmit(optionsDelLayer);

    return false;
});
function showRequestDelLayer(formData, jqForm, optionsDelLayer) {
    return true;
}
function showResponseDelLayer(response) {
    if (response == 202){
        document.getElementById("requireDelLayer").style.display = "block";
    }
    else{
        window.location = 'http://' + window.vtParameters.djangoHost + ':' + window.vtParameters.djangoPort;
    }
}

// Close modal
var nav = document.getElementById("c-menu--slide-right");
window.onclick = function(event) {
    if (event.target == modalAddLayer) {
        modalAddLayer.style.display = "none";
    }
    if (event.target == modalDelLayer) {
        modalDelLayer.style.display = "none";
    }
    if (event.target == btnDelLayer) {
        modalAddLayer.style.display = "none";
    }
    if (event.target == btnAddLayer) {
        modalDelLayer.style.display = "none";
    }
}