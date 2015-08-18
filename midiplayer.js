var cordova = require('cordova'),
    exec = require('cordova/exec');

var exec2 = function (methodName, options, success, error) {
    exec(success, error, "MidiPlayer", methodName, options);
};

var MidiPlayer = function () {};

MidiPlayer.prototype = {
    getPathFromAsset: function(path) {
        if(device.platform == "Android")
        {
            return "www/"+path;
        }
        var finalPath = cordova.file.applicationDirectory + "www/" + path;
        finalPath = finalPath.substr(7);
        return finalPath;
    },
    setup: function (midiFilePath, programs, success, error, status) {
        exec2("setup", [midiFilePath, programs], function (statusValue) {
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
        exec2("play", [], function() { console.log("success play"); }, function(err) { console.log("error play:" + err); });    
    },
    pause: function () {
        exec2("pause", [], null, null);    
    },
    stop: function () {
        exec2("stop", [], null, null);    
    },
    getCurrentPosition: function (success, error) {
        exec2("getCurrentPosition", [], success, error);    
    },
    seekTo: function (position) {
        exec2("seekTo", [position], null, null);    
    },
    release: function () {
        exec2("release", [], null, null);    
    }
};

var midiPlayer = new MidiPlayer();
module.exports = midiPlayer;