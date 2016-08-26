// Setup the form
function setupForm(formId, url) {
    // Get the form
    var form = document.getElementById(formId);
    if (form && window.FormData) {
        // Listen for the form being submitted
        form.addEventListener('submit', function(evt) {
            evt.preventDefault();
            sendForm(event.target, url);
        });
    }
}

// Send the form
function sendForm(form, url) {
    // Create a new formData
    var formData = new FormData(form);

    // Set up the AJAX request
    var request = new XMLHttpRequest();
    request.open('POST', url, true);

    // Watch for changes to request.readyState
    request.onload = function() {
        handleFormRequest(request);
    };

    // Send the formData
    request.send(formData);
}

// Display or hide all .requirelayer
function toggle(displayState){
    var elements = document.getElementsByClassName('requireLayer')

    for (var i = 0; i < elements.length; i++){
        elements[i].style.display = displayState;
    }
}

// Handle the request
function handleFormRequest(request) {
    if (request.readyState === 4) {
        if (request.status === 200) {
            window.location = '/';
        } else if (request.status === 202) {
            toggle('block');
        }
    }
}

// Add layer
var modalAddLayer = document.getElementById('myModalAddLayer');
var btnAddLayer = document.getElementById("myBtnAddLayer");
var spanAddLayer = document.getElementsByClassName("closeAddLayer")[0];

btnAddLayer.onclick = function() {
    modalAddLayer.style.display = "block";
    toggle('none');
}

spanAddLayer.onclick = function() {
    modalAddLayer.style.display = "none";
}

setupForm('form_add_layer', '/add-layer');

// Delete layer
var modalDelLayer = document.getElementById('myModalDelLayer');
var btnDelLayer = document.getElementById("myBtnDelLayer");
var spanDelLayer = document.getElementsByClassName("closeDelLayer")[0];

btnDelLayer.onclick = function() {
    modalDelLayer.style.display = "block";
    toggle('none');
}

spanDelLayer.onclick = function() {
    modalDelLayer.style.display = "none";
}

setupForm('form_delete_layer', '/delete-layer', 'delLayer');

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