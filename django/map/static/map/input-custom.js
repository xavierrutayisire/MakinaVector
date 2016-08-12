// Create the sibling for input and label
var inputs = document.querySelectorAll( '.input-design' );
Array.prototype.forEach.call( inputs, function( input )
{
	var label	 = input.nextElementSibling,
		labelVal = label.innerHTML;

	input.addEventListener( 'change', function( e )
	{
		var fileName = '';
		fileName = e.target.value.split( '\\' ).pop();

		if( fileName ) {
			label.querySelector( 'span' ).innerHTML = fileName;
            document.getElementById('requireAddLayer').style.display = 'none';
        }
		else
			label.innerHTML = labelVal;
	});
});

// Change the required message
document.addEventListener("DOMContentLoaded", function() {
    var element = document.getElementById("fileGeoJSON");
    element.oninvalid = function(e) {
        e.target.setCustomValidity("");
        if (!e.target.validity.valid) {
            document.getElementById('requireAddLayer').style.display = 'block';
        }
    };
    element.oninput = function(e) {
        e.target.setCustomValidity("");
    };
})

// Prevent the display of the orignal required message
$('#fileGeoJSON').on("invalid", function(e) {
    e.preventDefault();
});