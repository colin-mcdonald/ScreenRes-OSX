//
//  AppDelegate.h
//  ScreenRes
//
//  Created by Colin McDonald on 2013-10-07.
//  Copyright (c) 2013 Colin McDonald. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window; //TODO: remove
@property (assign) IBOutlet NSMenu *statusMenu;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
