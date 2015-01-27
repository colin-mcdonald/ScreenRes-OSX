//
//  DisplayMode.m
//  ScreenRes
//
//  Created by Colin McDonald on 2014-12-21.
//  Copyright (c) 2014 Colin McDonald. All rights reserved.
//

#import "DisplayMode.h"
#import "cg_utils.h"

@implementation DisplayMode

- (DisplayMode *) initWithCGDisplayModeInfo:(CGDisplayModeRef) mode {
    if(self = [super init]) {
        _mode = mode;
        _width = CGDisplayModeGetWidth(mode);
        _height = CGDisplayModeGetHeight(mode);
        _refreshRate = CGDisplayModeGetRefreshRate(mode);
        _bitDepth = bitDepth(mode);
    }
    
    return self;
}

- (NSString *) aspectRatioDescription {
    float division = self.width / self.height;
    
    if (division == 16.0f/9.0f || division == 384.0f/683.0f )
        return @"16:9";
    else if (division == 16.0f/10.0f)
        return @"16:10";
    else if (division == 4.0f/3.0f)
        return @"4:3";
    else if(division == 5.0f/4.0f)
        return @"5:4";
    
    return @"Unknown";
}

- (BOOL) makeActive {
    return [self.monitor setActiveMode:self];
}

-(NSString *) resolutionDescription {
    // return formatted string representation of a given display mode
    if (self.width < 1000) {
        return [NSString stringWithFormat:@"%.0f  x %.0f",
                self.width,
                self.height];
    } else {
        return [NSString stringWithFormat:@"%.0f x %.0f",
                self.width,
                self.height];
    }
}

-(NSString *) fullDescription {
    // return formatted string representation of a given display mode
    return [NSString stringWithFormat:@"%.0f x %.0f @ %.0fhz (%.0f bit) %@",
            self.width,
            self.height,
            self.refreshRate,
            self.bitDepth,
            self.aspectRatioDescription];
}

@end


