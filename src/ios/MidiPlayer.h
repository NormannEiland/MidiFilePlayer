#import <Cordova/CDV.h>
#import <AudioToolbox/AudioToolbox.h>
@interface MidiPlayer : CDVPlugin {
    MusicPlayer mp;
    MusicSequence ms;
    Float64 longestTrackLength;
    MusicTimeStamp longestTrackBeats;
    
    NSString* setupCallbackId;
    
    BOOL released;
    BOOL stopped;
    BOOL paused;
}

@property (readwrite) AUGraph processingGraph;

- (void) play: (CDVInvokedUrlCommand*)command;
@end