(function () {
    document.addEventListener("deviceready", function () {
        
		// Get the absolute path of the midi file
		var finalPath = cordova.file.applicationDirectory + "www/Test.mid";
		
		// Removes the "file://" at the begining of the path
		finalPath = finalPath.substr(7);
		
		// Setup player and start playing
		MidiPlayer.setup(
			finalPath,
			["1"], 
			function(data) {
				console.log("Setup finished") ;
				MidiPlayer.play();
			},
			function(data) {
				console.log("Error occured: ", data) ;
			},
			function(data) {
				console.log("Status Updates: ", data) ;
			}
		);
        
    });
}());