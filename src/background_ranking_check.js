var MILLIMAS_ROOT = 'http://imas.gree-apps.net/app/';

chrome.alarms.onAlarm.addListener(function(alarm) {
    if (alarm) {
        if (alarm.name == 'ranking_check') {
            console.log('alarmed.');
            fetchRankingData();
        }
    }
});

function fetchRankingData() {
    if(typeof $ !== 'function' || $ != jQuery) {
        console.log('jquery is not found.');
        var d=document;
        var jq=d.createElement('script');
        jq.src='https://ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js';
        jq.onload=function() {_fetchRankingData()};
        d.body.appendChild(jq);
    } else {
        console.log('jquery is found.');
        _fetchRankingData();
    }
};

function _fetchRankingData(step) {
    console.log('fetch ranking...');
    var step = step || 'myrank';

    switch (step) {
        case 'myrank':
            requestPage('index.php/event/ranking').done(function(data) {
                localStorage['myrank'] = $("#user-ranking table.txt-left tr:eq(0) td", data).text().match(/\d+/);
                localStorage['mypt'] = $("#user-ranking table.txt-left tr:eq(1) td", data).text().match(/\d+/);

                _fetchRankingData('border1200');
            });
            break;
        case 'border1200':
            requestPage('index.php/event/ranking/page/120').done(function(data) {
                localStorage['border1200'] = $(".list-bg li:eq(12) td:eq(1)", data).text().match(/\d+\spt/)[0].match(/\d+/);

                _fetchRankingData('done');
            });
            break;
        case 'done':
            var message = "current rank: " + localStorage['myrank']
                        + "\r\ncurrent pt: " + localStorage['mypt']
                        + "( border:" + localStorage['border1200'] + ")";
            var notice_id = "mr_" + Date.now();
            chrome.notifications.create(notice_id, {type: "basic", title: "Ranking Notify", message: message, iconUrl: "../img/icon48.png"}, function() { console.log('notified.'); });
            break;
    }
}

function requestPage(req_uri) {
    var df = $.Deferred();
    $.ajax({
        url: MILLIMAS_ROOT + req_uri,
        success: function(data) {
            df.resolve(data);
        }
    });
    return df.promise();
}