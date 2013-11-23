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

var sub_border = localStorage['mypt'] - localStorage['border1200'];

$('#mr_popup_myrank').text('現在の順位：' + localStorage['myrank'] +'位');
$('#mr_popup_mypt').html('現在のpt：' + localStorage['mypt'] + ' pt<br>'
 + '(ボーダー比: ' + sub_border + ')');