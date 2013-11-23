var MillimasExtension = MillimasExtension || {};

//(function() {
chrome.runtime.onInstalled.addListener(function() {
    console.log('onInstalled.');
    chrome.alarms.create('ranking_check', {periodInMinutes: 5});
    fetchRankingData();
});

chrome.runtime.onStartup.addListener(function() {
    console.log('onStartup.');
    chrome.alarms.create('ranking_check', {periodInMinutes: 5});
});
//})();
