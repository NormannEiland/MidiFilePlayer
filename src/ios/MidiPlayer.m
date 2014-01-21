#import "MidiPlayer.h"
#import <Cordova/CDV.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation MidiPlayer

BOOL released = YES;
BOOL stopped = YES;
BOOL paused = NO;

- (void)setup:(CDVInvokedUrlCommand*)command
{
    //NSLog(@"Setup");
    NSString* path = [command.arguments objectAtIndex:0];
    setupCallbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        //NSLog(@"Setup background");
        CDVPluginResult* pluginResult = nil;
        if (path != nil && [path length] > 0) {
            CDVPluginResult* pluginResult;
            BOOL success = [self setupPlayer:path];
            if (success) {
                released = NO;
                stopped = YES;
                paused = NO;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
                [self playerLoop];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
        }
    }];
}

- (void)play:(CDVInvokedUrlCommand*)command
{
    //NSLog(@"Play %i", released);
    CDVPluginResult* pluginResult = nil;
    if (ms == nil || released || !(stopped || paused)) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        MusicPlayerStart(mp);
        stopped = NO;
        paused = NO;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if (ms == nil || stopped || released) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        MusicPlayerStop(mp);
        [self setTime: 0];
        
        stopped = YES;
        paused = NO;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pause:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if (ms == nil || paused || stopped || released) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        MusicPlayerStop(mp);
        stopped = NO;
        paused = YES;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if (ms == nil || released) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        Float64 time = [self getTime];
        // Don't return more than track length
        if (time > longestTrackLength) {
            time = longestTrackLength;
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%f",time]];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (Float64)getTime {
    MusicTimeStamp beats = 0;
    MusicPlayerGetTime (mp, &beats);
    Float64 time;
    MusicSequenceGetSecondsForBeats(ms, beats, &time);
    //NSLog(@"GetTime: %f", time);
    return time;
}

- (void)seekTo:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    if (released) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString* timeStr = [command.arguments objectAtIndex:0];
    Float64 time = [timeStr floatValue];
    time = time / 1000;
    //NSLog(@"SetTime: %f", time);
    [self setTime:time];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setTime:(Float64)time {
    MusicTimeStamp beats = 0;
    MusicSequenceGetBeatsForSeconds(ms, time, &beats);
    MusicPlayerSetTime(mp, beats);
}

- (void)release:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if (ms == nil || released) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        if (!(stopped && paused)) {
            MusicPlayerStop(mp);
        }
        DisposeMusicSequence(ms);
        released = true;
        //NSLog(@"DoRelease");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (BOOL)setupPlayer:(NSString*)path {
    // Initialise the music sequence
    NewMusicSequence(&ms);
    
    NSURL * midiFileURL;
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [pathArray objectAtIndex:0];
    NSString *midiPath = [documentsDirectory stringByAppendingPathComponent:path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:midiPath])
    {
        midiFileURL = [NSURL fileURLWithPath:midiPath isDirectory:NO];
    } else {
        return NO;
    }
    
    MusicSequenceFileLoad(ms, (__bridge CFURLRef)(midiFileURL), 0, 0);
    
    NewMusicPlayer(&mp);
    
    // Load the sequence into the music player
    MusicPlayerSetSequence(mp, ms);
    
    MusicPlayerPreroll(mp);
    
    [self setLongestTrackLength];
    
    return YES;
}

- (void)setLongestTrackLength {
    UInt32 trackCount;
    MusicSequenceGetTrackCount(ms, &trackCount);
    
    MusicTimeStamp longest = 0;
    for (int i = 0; i < trackCount; i++) {
        MusicTrack t;
        MusicSequenceGetIndTrack(ms, i, &t);
        
        MusicTimeStamp len;
        UInt32 sz = sizeof(MusicTimeStamp);
        MusicTrackGetProperty(t, kSequenceTrackProperty_TrackLength, &len, &sz);
        if (len > longest) {
            longest = len;
        }
    }
    Float64 longestTime;
    MusicSequenceGetSecondsForBeats(ms, longest, &longestTime);
    longestTrackBeats = longest;
    longestTrackLength = longestTime;
}

- (void)playerLoop {
    BOOL lastStopped = stopped;
    BOOL lastPaused = paused;
    CDVPluginResult* pluginResult;
    while (!released) {
        if (stopped) {
            //NSLog(@"isStopped, lastStopped:%i", lastStopped);
            if (!lastStopped) {
                // Was just stopped
                //NSLog(@"Stopped");
                lastStopped = stopped;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: 0];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
            }
        } else if (paused) {
            //NSLog(@"isPaused");
            if (!lastPaused) {
                //NSLog(@"Paused");
                // Was just paused
                lastPaused = paused;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: 3];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
            }
        } else {
            // Running
            //NSLog(@"NowRunning");
            if ([self getTime] >= longestTrackLength) {
                // Track reached end
                //NSLog(@"Ended");
                stopped = YES;
                lastStopped = YES;
                paused = NO;
                lastPaused = NO;
                MusicPlayerStop(mp);
                [self setTime: 0];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: 0];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
            } else if (lastPaused || lastStopped) {
                // Just started running
                //NSLog(@"Running");
                lastPaused = NO;
                lastStopped = NO;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: 2];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
            }
        }
        [NSThread sleepForTimeInterval:.01];
    }
    //NSLog(@"Released");
    stopped = YES;
    paused = NO;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: 0];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:setupCallbackId];
    
}
@end