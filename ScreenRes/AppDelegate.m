#import "AppDelegate.h"
#import "cg_utils.h"

@interface AppDelegate()
    @property (assign) IBOutlet NSMenu *statusMenu;
    @property (nonatomic, strong) NSMutableArray *currentDisplayMode;
    @property (nonatomic, strong) NSMutableArray *displayModesArray;
    @property (nonatomic, strong) NSMutableArray *menuItemsArray;
    @property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

@synthesize statusMenu, displayModesArray, menuItemsArray, statusItem, currentDisplayMode;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // stub
}

-(void)awakeFromNib {
    // when app first starts, populate available display modes
    // in status bar menu for each active display
    [self configureStatusBar];
}

-(void) applicationDidChangeScreenParameters:(NSNotification *)notification {
    // when screen resolutions change, monitors are plugged-in or unplugged etc,
    // this  method will get fired to re-populate the display options menu
    [self configureStatusBar];
}

-(IBAction) quitApp:(id) sender {
    // terminate application at user's request...
    [[NSApplication sharedApplication] terminate:nil];
}

-(void) configureStatusBar {
    // set status bar icon properties
    if(nil == self.statusItem) {
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [self.statusItem setImage:[NSImage imageNamed:@"Icon.png"]];
        self.statusItem.image.size = NSMakeSize(19, 19);
        [self.statusItem setHighlightMode:YES];
    }
    
    // get supported display modes for each display, save in array
    self.displayModesArray = [self populateDisplayModesArray];
    
    // populate menu items from array of supported display modes
    self.menuItemsArray = [self populateStatusBarMenuOptionsFromDisplayArray:self.displayModesArray];
    [self configureStatusMenu:self.statusMenu WithOptions:self.menuItemsArray];
    [self.statusItem setMenu:self.statusMenu];
}

-(void) configureStatusMenu:(NSMenu *)menu WithOptions:(NSArray *) menuItems {
    // clear existing menu options before populating
    [menu removeAllItems];
    
    // create submenu for each active display
    for(int i=0; i < menuItems.count; i++)
    {
        // add item in main status bar menu for display
        NSString *subMenuTitle = [NSString stringWithFormat:@"Display %d", (i + 1)];
        NSMenuItem *displayButton = [[NSMenuItem alloc] initWithTitle:subMenuTitle action:nil keyEquivalent:@""];
        [menu addItem:displayButton];
        
        // populate display submenu with it's supported display modes
        NSMenu *displayMenu = [[NSMenu alloc] init];
        for(int j=0; j < ((NSArray *)menuItems[i]).count; j++) {
            [displayMenu addItem:menuItems[i][j]];
        }
        
        [menu setSubmenu:displayMenu forItem:displayButton];
    }
    
    // add the 'Quit' option to main application menu
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

-(NSString *) stringFromDisplayMode:(CGDisplayModeRef) mode {
    // return formatted string representation of a given display mode
    return [NSString stringWithFormat:@"%zu x %zu @ %.0fhz (%zu bit)",
            CGDisplayModeGetWidth(mode),
            CGDisplayModeGetHeight(mode),
            CGDisplayModeGetRefreshRate(mode),
            bitDepth(mode)];
}

@end