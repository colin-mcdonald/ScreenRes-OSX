//
//  DisplayMode.h
//  ScreenRes
//
//  Created by Colin McDonald on 2014-12-21.
//  Copyright (c) 2014 Colin McDonald. All rights reserved.
//

#ifndef ScreenRes_DisplayMode_h
#define ScreenRes_DisplayMode_h

@protocol DisplayModeDelegate;

@interface DisplayMode : NSObject

@property (nonatomic, readonly) CGDisplayModeRef mode;
@property (nonatomic, weak) id<DisplayModeDelegate> monitor;
@property (nonatomic, readonly) double width;
@property (nonatomic, readonly) double height;
@property (nonatomic, readonly) double refreshRate;
@property (nonatomic, readonly) double bitDepth;
@property (nonatomic, readonly) NSString *resolutionDescription;
@property (nonatomic, readonly) NSString *refreshRateDescription;
@property (nonatomic, readonly) NSString *aspectRatioDescription;
@property (nonatomic, readonly) NSString *fullDescription;

- (DisplayMode *) initWithCGDisplayModeInfo:(CGDisplayModeRef) mode;
- (BOOL) makeActive;

@end

@protocol DisplayModeDelegate
- (BOOL) setActiveMode:(DisplayMode *) mode;
@end

#endif
