var MillimasExtension = MillimasExtension || {};

//(function() {
chrome.runtime.onInstalled.addListener(function() {
    // 拡張のインストール時やバージョンアップ時に呼ばれる
    chrome.alarms.create('ranking_check', {periodInMinutes: 1});
});

chrome.runtime.onStartup.addListener(function() {
    chrome.alarms.create('ranking_check', {periodInMinutes: 1});
});

chrome.alarms.onAlarm.addListener(function(alarm) {
    if (alarm) {
        if (alarm.name == 'ranking_check') {
            var notice_id = "mr_" + Date.now();

            chrome.notifications.create(notice_id, {type: "basic", title: "Information", message: "Ranking Update!!", iconUrl: "../img/icon48.png"}, function() {});
        }
    }
});

/*
    function getRankingStatus(onSuccess, onError) {
        var xhr = new XMLHttpRequest();
    }

    if (chrome.runtime && chrome.runtime.onStartup) {
        chrome.runtime.onStartup.addListener(function() {
            startRequest();
        });
    } else {
        chrome.windows.onCreated.addListener(function() {
            startRequest();
        });
    }
*/
//})();
