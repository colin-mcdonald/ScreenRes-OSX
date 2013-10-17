//
//  AppDelegate.m
//  ScreenRes
//
//  Created by Colin McDonald on 2013-10-07.
//  Copyright (c) 2013 Colin McDonald. All rights reserved.
//

#import "AppDelegate.h"
#import "../screenresolution/cg_utils.h"

@interface AppDelegate()
@property (nonatomic, strong) NSMutableArray *currentDisplayMode;
@property (nonatomic, strong) NSMutableArray *displayModesArray;
@property (nonatomic, strong) NSMutableArray *menuItemsArray;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize statusMenu, displayModesArray, menuItemsArray, statusItem, currentDisplayMode;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

-(void)awakeFromNib
{
    [self configureStatusBar];
}

-(void) configureStatusBar {
    self.displayModesArray = [self populateDisplayModesArray];
    self.menuItemsArray = [self populateStatusBarMenuOptionsFromDisplayArray:self.displayModesArray];
    [self configureStatusMenu:self.statusMenu WithOptions:self.menuItemsArray];
    
    if(nil == self.statusItem) {
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [self.statusItem setImage:[NSImage imageNamed:@"Icon2.png"]];
        self.statusItem.image.size = NSMakeSize(19, 19);
        [self.statusItem setHighlightMode:YES];
    }
    
    [self.statusItem setMenu:self.statusMenu];
}

-(void) applicationDidChangeScreenParameters:(NSNotification *)notification {
    [self configureStatusBar];
}

-(void) configureStatusMenu:(NSMenu *)menu WithOptions:(NSArray *) menuItems {
    [menu removeAllItems];
    
    for(int i=0; i < menuItems.count; i++)
    {
        NSString *subMenuTitle = [NSString stringWithFormat:@"Display %d", (i + 1)];
        NSMenuItem *displayButton = [[NSMenuItem alloc] initWithTitle:subMenuTitle action:nil keyEquivalent:@""];
        
        [menu addItem:displayButton];
        
        NSMenu *displayMenu = [[NSMenu alloc] init];
        
        for(int j=0; j < ((NSArray *)menuItems[i]).count; j++) {
            [displayMenu addItem:menuItems[i][j]];
        }
        
        [menu setSubmenu:displayMenu forItem:displayButton];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quitApp:) keyEquivalent:@""];
    [menu addItem:quitItem];
}

-(NSMutableArray *) populateDisplayModesArray {
    NSMutableArray *displayModes = [[NSMutableArray alloc] init];
    
    uint32_t displayCount = 0;
    uint32_t activeDisplayCount = 0;
    CGDirectDisplayID *activeDisplays = NULL;
    
    CGError rc;
    rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
    if (rc != kCGErrorSuccess) {
        NSLog(@"Error: failed to get list of active displays");
    }
    
    activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
    if (activeDisplays == NULL) {
        NSLog(@"Error: could not allocate memory for display list");
    }
    
    //TODO: should check the 'online' display list as well...then we can tell if
    // hardware mirroring is being used, and can indicate that in the GUI
    rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
    if (rc != kCGErrorSuccess) {
        NSLog(@"Error: failed to get list of active displays");
    }
    
    // populate available display modes for each display
    for(int i=0; i < activeDisplayCount; i++) {
        [displayModes addObject:[[NSMutableArray alloc] init]];
        
        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(activeDisplays[i], NULL);
        
        for (int j = 0; j < CFArrayGetCount(allModes); j++) {
            CGDisplayModeRef mode = (CGDisplayModeRef) CFArrayGetValueAtIndex(allModes, j);
            [displayModes[i] addObject:(__bridge id)(mode)];
        }
    }
    
    for(int i = 0; i < activeDisplayCount; i++)
    {
        // sort the available display modes for each display
        // first by width, then by height, then by refresh rate, then by bit depth
        [displayModes[i] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CGDisplayModeRef mode1 = (__bridge CGDisplayModeRef)(obj1);
            CGDisplayModeRef mode2 = (__bridge CGDisplayModeRef)(obj2);
            
            NSInteger width1 = CGDisplayModeGetWidth(mode1);
            NSInteger width2 = CGDisplayModeGetWidth(mode2);
            
            if(width1 == width2) {
                NSInteger height1 = CGDisplayModeGetWidth(mode1);
                NSInteger height2 = CGDisplayModeGetWidth(mode2);
                
                if(height1 == height2) {
                    double refreshRate1 = CGDisplayModeGetRefreshRate(mode1);
                    double refreshRate2 = CGDisplayModeGetRefreshRate(mode2);
                    
                    if(refreshRate1 == refreshRate2) {
                        long bitDepth1 = bitDepth(mode1);
                        long bitDepth2 = bitDepth(mode2);
                        
                        if(bitDepth1 == bitDepth2)
                            return NSOrderedSame;
                        else
                            return bitDepth1 < bitDepth2 ? NSOrderedDescending : NSOrderedAscending;
                    }
                    else {
                        return refreshRate1 < refreshRate2 ? NSOrderedDescending : NSOrderedAscending;
                    }
                }
                else {
                    return height1 < height2 ? NSOrderedDescending : NSOrderedAscending;
                }
            }
            else {
                return width1 < width2 ? NSOrderedDescending : NSOrderedAscending;
            }
        }];
        
        // add current display mode at index 0 of each display mode array
        CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(activeDisplays[i]);
        [displayModes[i] insertObject:(__bridge id)(currentMode) atIndex:0];
    }
    
    return displayModes;
}

-(NSMutableArray *) populateStatusBarMenuOptionsFromDisplayArray:(NSArray *) displayModes {
    NSMutableArray *menuItems = [[NSMutableArray alloc] init];
    
    for(int i=0; i < displayModes.count; i++)
    {
        [menuItems addObject:[[NSMutableArray alloc] init]];
        
        for (int j = 1; j < ((NSMutableArray *)displayModes[i]).count; j++) {
            CGDisplayModeRef mode = (__bridge CGDisplayModeRef) displayModes[i][j];
            NSString *modeDescription = [self stringFromDisplayMode:mode];
            
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:modeDescription action:@selector(displayOptionWasSelected:) keyEquivalent:@""];
            
            // place checkmark on current display mode
            [menuItem setState: (displayModes[i][0] == displayModes[i][j])];
            [menuItems[i] addObject:menuItem];
        }
    }
    
    return menuItems;
}

-(NSString *) stringFromDisplayMode:(CGDisplayModeRef) mode {
    return [NSString stringWithFormat:@"%zu x %zu @ %.0fhz (%zu bit)",
                                 CGDisplayModeGetWidth(mode),
                                 CGDisplayModeGetHeight(mode),
                                 CGDisplayModeGetRefreshRate(mode),
                                 bitDepth(mode)];
}

-(IBAction) displayOptionWasSelected:(id) sender {
    for(int idxDisplay = 0; idxDisplay < menuItemsArray.count; idxDisplay++)
    {
        for(int idxMode = 0; idxMode < ((NSMutableArray *)menuItemsArray[idxDisplay]).count; idxMode++)
        {
            if(menuItemsArray[idxDisplay][idxMode] == sender) {
                // add one to index because index 0 is current mode
                CGDisplayModeRef mode = (__bridge CGDisplayModeRef)((displayModesArray[idxDisplay][idxMode + 1]));

                //NSLog(@"SELECTED: %@ on display: %d", [self stringFromDisplayMode:mode], idxDisplay);
                
                uint32_t displayCount = 0;
                uint32_t activeDisplayCount = 0;
                CGDirectDisplayID *activeDisplays = NULL;
                
                //TODO: duplicated code
                CGError rc;
                rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
                if (rc != kCGErrorSuccess) {
                    NSLog(@"Error: failed to get list of active displays");
                }
                
                activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
                if (activeDisplays == NULL) {
                    NSLog(@"Error: could not allocate memory for display list");
                }
                
                rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
                if (rc != kCGErrorSuccess) {
                    NSLog(@"Error: failed to get list of active displays");
                }
                
                CGDirectDisplayID display = activeDisplays[idxDisplay];
                setDisplayToMode(display, mode);
                break;
            }
        }
    }
}

-(IBAction) quitApp:(id) sender {
    [[NSApplication sharedApplication] terminate:nil];
}

/*
unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode) {
    NSLog(@"%d", display);
    CGError rc;
    CGDisplayConfigRef config;
    rc = CGBeginDisplayConfiguration(&config);
    if (rc != kCGErrorSuccess) {
        NSLog(@"Error: failed CGBeginDisplayConfiguration err(%u)", rc);
        return 0;
    }
    rc = CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
    if (rc != kCGErrorSuccess) {
        NSLog(@"Error: failed CGConfigureDisplayWithDisplayMode err(%u)", rc);
        return 0;
    }
    rc = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (rc != kCGErrorSuccess) {
        NSLog(@"Error: failed CGCompleteDisplayConfiguration err(%u)", rc);
        return 0;
    }
    return 1;
}

size_t bitDepth(CGDisplayModeRef mode) {
    size_t depth = 0;
    CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding(mode);
    // my numerical representation for kIO16BitFloatPixels and kIO32bitFloatPixels
    // are made up and possibly non-sensical
    if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO32BitFloatPixels), kCFCompareCaseInsensitive)) {
        depth = 96;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO64BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 64;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO16BitFloatPixels), kCFCompareCaseInsensitive)) {
        depth = 48;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 32;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO30BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 30;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 16;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive)) {
        depth = 8;
    }
    CFRelease(pixelEncoding);
    return depth;
}
*/

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "m.com.colin-mcdonald.ScreenRes" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"m.com.colin-mcdonald.ScreenRes"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ScreenRes" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"ScreenRes.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
