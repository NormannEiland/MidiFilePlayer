var exec = function (methodName, options, success, error) {
    cordova.exec(success, error, "MidiPlayer", methodName, options);
};

var MidiPlayer = function () {
};

MidiPlayer.prototype = {
    setup: function (midiFilePath, success, error, status) {
	exec("setup", [midiFilePath], function (statusValue) {
	    //console.log("Status: " + statusValue);
	    if (statusValue === "success") {
		if (success) {
		    success();
		}
		return;
	    }
	    if (status) {
		status(statusValue);
	    }
	}, error);    
    },
    play: function () {
	exec("play", [], null, null);    
    },
    pause: function () {
	exec("pause", [], null, null);    
    },
    stop: function () {
	exec("stop", [], null, null);    
    },
    getCurrentPosition: function (success, error) {
	exec("getCurrentPosition", [], success, error);    
    },
    seekTo: function (position) {
	exec("seekTo", [position], null, null);    
    },
    release: function () {
	exec("release", [], null, null);    
    }
};

module.exports = new MidiPlayer();

