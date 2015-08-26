(function () {
    document.addEventListener("deviceready", function ()
	{
        
        MidiPlayer.setup(
            MidiPlayer.getPathFromAsset("demo.mid"),
            ["1","2","3","4","5"], 
            function() {
                MidiPlayer.play();
            },
            function(data) {
                console.log("Error occured:", data) ;
            },
            function(data) {
                console.log("Status Updates: ", data) ;
            }
        );
        
    });
}());