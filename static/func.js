function toggleInfo() {
    document.getElementById("help").style.display = "block";
}

function closeInfo() {
    document.getElementById("help").style.display = "none";
}

function Upload() {
    var intext = document.getElementById('input').value;
    var m = "m1";
    $.ajax({
        type: "POST",
        url: "/remine",
        data: { text: intext, model: m }
    }).done(function(e) {
        console.log(e);
    });
}
