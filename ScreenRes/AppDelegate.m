#import "AppDelegate.h"
#import "cg_utils.h"
#import "Sparkle/Sparkle.h"
#import "DisplayMonitor.h"
#import "DisplayMode.h"

@interface AppDelegate()

@property (nonatomic, strong) NSMutableArray *displaysList;
@property (nonatomic, strong) NSStatusItem *statusItem;

@end

@implementation AppDelegate

@synthesize displaysList, statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:@"https://screenresosx.colin-mcdonald.com/appcast.xml" forKey:@"SUFeedURL"];
}

-(void)awakeFromNib {
    [self getDisplayInfo];
    [self configureStatusBar];
}

// when screen resolutions change, monitors are plugged-in or unplugged etc,
// this  method will get fired to re-populate the display options menu
-(void) applicationDidChangeScreenParameters:(NSNotification *)notification {
    [self getDisplayInfo];
    [self configureStatusBar];
}

-(IBAction) quitApp:(id) sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction) checkForUpdates:(id)sender {
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

-(IBAction) displayOptionWasSelected:(id) sender {
    DisplayMode *selectedDisplayMode = [sender representedObject];
    [selectedDisplayMode makeActive];
    [self configureStatusBar];
}

-(void) getDisplayInfo {
    self.displaysList = [[NSMutableArray alloc] init];
    
    uint32_t displayCount = 0;
    uint32_t activeDisplayCount = 0;
    
    CGError rc;
    rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
    if (rc == kCGErrorSuccess) {
        CGDirectDisplayID activeDisplays[activeDisplayCount];
        
        //TODO: should check the 'online' display list as well...then we can tell if
        // hardware mirroring is being used, and can indicate that in the GUI
        rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
        if (rc != kCGErrorSuccess) {
            NSLog(@"Error: failed to get list of active displays");
        }
        
        // populate available display modes for each display
        for(int i=0; i < activeDisplayCount; i++) {
            DisplayMonitor *dm = [[DisplayMonitor alloc] initWithCGDisplayID:activeDisplays[i]];
            [self.displaysList addObject:dm];
        }
    } else {
        NSLog(@"Error: failed to get list of active displays");
    }
}

-(void) configureStatusBar {
    // set status bar icon properties
    if(nil == self.statusItem) {
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [self.statusItem setImage:[NSImage imageNamed:@"Icon.png"]];
        self.statusItem.image.size = NSMakeSize(19, 19);
        [self.statusItem setHighlightMode:YES];
    }
    
    NSMenu *statusMenu = [[NSMenu alloc] initWithTitle:@"Display Modes"];

    for(DisplayMonitor* dm in self.displaysList)
    {
        NSString *subMenuTitle = dm.displayName;
        NSMenuItem *displayButton = [[NSMenuItem alloc] initWithTitle:subMenuTitle action:nil keyEquivalent:@""];
        [statusMenu addItem:displayButton];

        NSMenu *displayMenu = [[NSMenu alloc] init];
        
        NSArray *displayModesSorted = [dm.displayModes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [((DisplayMode *)obj1).aspectRatioDescription compare:((DisplayMode *)obj2).aspectRatioDescription];
        }];
        
        NSString *currAspRatio = nil;
        NSString *currTitle = nil;
        for(DisplayMode *displayMode in displayModesSorted) {
            NSString *menuItemTitle = displayMode.resolutionDescription;
            
            // make sure no duplicate menu items are shown
            if ([menuItemTitle isEqualToString:currTitle]) {
                continue;
            }
            
            currTitle = menuItemTitle;
            
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle
                                                action:@selector(displayOptionWasSelected:)
                                                keyEquivalent:@""];
            
            NSMutableAttributedString* str =[[NSMutableAttributedString alloc]initWithString:menuItemTitle];
            [str setAttributes: @{ NSFontAttributeName : [NSFont fontWithName: @"Courier New" size: 14.0] } range: NSMakeRange(0, [str length])];
            [menuItem setAttributedTitle:str];
            [menuItem setRepresentedObject:displayMode];
            
            // place checkmark on current display mode
            [menuItem setState: (displayMode == dm.activeMode)];
            
            if(displayMode.aspectRatioDescription != currAspRatio) {
                NSMenuItem *groupTitleItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ Aspect Ratio", displayMode.aspectRatioDescription]
                    action:nil
                    keyEquivalent:@""];
                [groupTitleItem setEnabled:NO];
                [displayMenu addItem:[NSMenuItem separatorItem]];
                [displayMenu addItem:groupTitleItem];
                currAspRatio = displayMode.aspectRatioDescription;
            }
            
            [displayMenu addItem:menuItem];
        }

        [statusMenu setSubmenu:displayMenu forItem:displayButton];
    }

    // sparkle updater - check for updates
    [statusMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *updateItem = [[NSMenuItem alloc] initWithTitle:@"Check For Updates..."
                                    action:@selector(checkForUpdates:)
                                    keyEquivalent:@""];
    [statusMenu addItem:updateItem];

    // add the 'Quit' option to main application menu
    [statusMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                    action:@selector(quitApp:)
                                    keyEquivalent:@""];
    [statusMenu addItem:quitItem];
    
    [self.statusItem setMenu:statusMenu];
}

@end