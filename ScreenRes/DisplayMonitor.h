//
//  DisplayMonitor.h
//  ScreenRes
//
//  Created by Colin McDonald on 2014-12-21.
//  Copyright (c) 2014 Colin McDonald. All rights reserved.
//

#import "DisplayMode.h"

#ifndef ScreenRes_DisplayMonitor_h
#define ScreenRes_DisplayMonitor_h

@interface DisplayMonitor : NSObject <DisplayModeDelegate>

@property (nonatomic, readonly) int displayIndex;
@property (nonatomic, readonly) CGDirectDisplayID cgDisplayID;
@property (nonatomic, readonly) DisplayMode *activeMode;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSArray *displayModes;

- (DisplayMonitor *) initWithCGDisplayID:(CGDirectDisplayID) displayID;

@end

#endif
