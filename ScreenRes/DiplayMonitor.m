//
//  DiplayMonitor.m
//  ScreenRes
//
//  Created by Colin McDonald on 2014-12-21.
//  Copyright (c) 2014 Colin McDonald. All rights reserved.
//

#import "DisplayMonitor.h"
#import "cg_utils.h"

@implementation DisplayMonitor

- (DisplayMonitor *) initWithCGDisplayID:(CGDirectDisplayID) displayID {
    if(self = [super init]) {
        _cgDisplayID = displayID;
        _displayIndex = 0;
        _displayName = [NSString stringWithFormat:@"%s", getPreferredDisplayName(displayID)];
        
        // set current mode
        CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(displayID);
        
        // populate display modes
        NSMutableArray *displayModesTemp = [[NSMutableArray alloc] init];
        
        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(displayID, NULL);
        
        // sort the array of display modes
        CFMutableArrayRef allModesSorted =  CFArrayCreateMutableCopy(
                                                                     kCFAllocatorDefault,
                                                                     CFArrayGetCount(allModes),
                                                                     allModes
                                                                     );
        
        CFArraySortValues(allModesSorted,
                          CFRangeMake(0, CFArrayGetCount(allModesSorted)),
                          (CFComparatorFunction) _compareCFDisplayModes,
                          NULL);
        
        for (long j = CFArrayGetCount(allModesSorted) - 1; j >= 0; j--) {
            CGDisplayModeRef mode = (CGDisplayModeRef) CFArrayGetValueAtIndex(allModesSorted, j);
            DisplayMode *displayMode = [[DisplayMode alloc] initWithCGDisplayModeInfo:mode];
            displayMode.monitor = self;
            [displayModesTemp addObject:displayMode];
            
            if (mode == currentMode){
                _activeMode = displayMode;
            }
        }
        
        _displayModes = [NSArray arrayWithArray:displayModesTemp];
    }
    
    return self;
}

- (BOOL) setActiveMode:(DisplayMode *) mode {
    if(setDisplayToMode(self.cgDisplayID, mode.mode)) {
        _activeMode = mode;
        return YES;
    } else {
        return NO;
    }
}

@end