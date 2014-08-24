window.onload = function() {
    g = new Dygraph(
        // containing div
        document.getElementById("graphdiv"),

        // path to csv file.
        'data/sample.csv'
    );
}
