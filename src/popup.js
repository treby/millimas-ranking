var opt = {
    type: "basic",
    title: "Information",
    iconUrl: "../img/icon48.png",
    message: "Ranking Update!!",
};

$('#gotoEventPage').click(function(e) {
    e.preventDefault();
    chrome.tabs.create({url: "http://imas.gree-apps.net/app/index.php/event"});
});

$('#getRankingStatus').click(function(e) {
    var notification_id = "notification" + Date.now();
    chrome.notifications.create(notification_id, opt, function() {});

    setTimeout(function() {
        chrome.notifications.clear(notification_id, function() {});
    }, 3000);
});
