$(function() {
    $.get('data/sample.csv', function (data) {
        var options = {
            chart: {
                type: 'spline'
            },
            title: {
                text: 'ranking border'
            },
            tooltip: {
                shared: true,
                crosshairs: true
            },
            xAxis: {
                categories: [],
                labels: {
                    enabled: false
                }
            },
            yAxis: {
                title: {
                    text: 'pt'
                },
                min: 0,
            },
            series: [],
        };
        var lines = data.split('\n');
        $.each(lines, function(lineNo, line) {
            var items = line.split(',');
            if (lineNo == 0) {
                $.each(items, function(itemNo, item) {
                    var series = {
                        data: []
                    };
                    if (itemNo > 0) {
                        series.name = item;
                        options.series.push(series);
                    }
                });
            } else {
                $.each(items, function(itemNo, item) {
                    if (itemNo == 0) {
                        options.xAxis.categories.push(item);
                    } else {
                        options.series[itemNo - 1].data.push(parseInt(item));
                    }
                });
            }
        });
        $('#container').highcharts(options);
    });
});
