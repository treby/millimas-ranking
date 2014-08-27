$(function() {
    $.get('data/sample.csv', function (data) {
        var options = {
            chart: {
                type: 'line'
            },
            title: {
                text: 'ranking border'
            },
            xAxis: {
                categories: []
            },
            yAxis: {
                title: {
                    text: 'pt'
                },
            },
            series: []
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
            } else if(items.length == 4) {
                $.each(items, function(itemNo, item) {
                    if (itemNo == 0) {
                        options.xAxis.categories.push('');
                    } else {
                        options.series[itemNo - 1].data.push(parseInt(item));
                    }
                });
            }
        });
        $('#container').highcharts(options);
    });
});
