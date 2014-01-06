//
//  AppDelegate.m
//  MaKeePass
//
//  Created by Taco van Dijk on 8/16/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

/*
 - implement password lock screen instead of alert with unlimited tries
 */

#import "AppDelegate.h"
#define KEY_P 35
#define INTERVAL_CLEAR_CLIP_SECONDS 10
#define INTERVAL_PASSWORD_MINUTES 15

@interface AppDelegate ()

- (void)searchGroup:(KdbGroup*)group searchText:(NSString*)searchText results:(NSMutableArray*)results;

@end

@implementation AppDelegate
@synthesize panelController;
@synthesize menubarController;
@synthesize currentEntry;
@synthesize keyPath;
@synthesize dbPath;
@synthesize lastTime;
@synthesize intervalPass;
@synthesize intervalClip;

#pragma mark -

- (void)dealloc
{
    [panelController removeObserver:self forKeyPath:@"hasActivePanel"];
    [currentEntry release];
    [super dealloc];
}

#pragma mark -

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:aKeyPath ofObject:object change:change context:context];
    }
}


- (IBAction)passwordAction:(id)sender {
    NSLog(@"copy password to clipboard");
    if(currentEntry)
    {
        //paste password to clipboard
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *objectsToCopy = [NSArray arrayWithObject:currentEntry.password];
        [pasteboard writeObjects:objectsToCopy];
        
        [self togglePanel:nil];
        [[NSApplication sharedApplication] hide:self];

        NSTimer *timer;
        timer = [NSTimer scheduledTimerWithTimeInterval: self.intervalClip.intValue
                                                 target: self
                                               selector: @selector(clearClipboardContents:)
                                               userInfo: nil
                                                repeats: YES];
    
    }
}

- (void) clearClipboardContents:(NSTimer *)timer {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [timer invalidate];
}

- (void) search:(NSString*)text
{
    //NSLog(@"search action: %@",text);
    //search through the results
    NSMutableArray * results = [[NSMutableArray alloc] initWithCapacity:0];
    [self searchGroup:[kdbTree root] searchText:text results:results];
    
    if([results count] > 0)
    {
        //print the first entry & password found
        self.currentEntry = [results objectAtIndex:0];
    }
}

- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    
    [[NSRunningApplication currentApplication] activateWithOptions:0];
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [input autorelease];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertAlternateReturn) {
        return nil;
    } else {
        //NSAssert1(NO, @"Invalid input dialog button %d", button);
        return nil;
    }
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.menubarController = [[MenubarController alloc] init];
    NSLog(@"init");
    
    //setup hotkey
    DDHotKeyCenter * c = [[DDHotKeyCenter alloc] init];
	if (![c registerHotKeyWithKeyCode:KEY_P modifierFlags:NSControlKeyMask target:self action:@selector(hotkeyWithEvent:    ) object:nil])
    {
        NSLog(@"Failed to register hotkey ctrl-p");
    }
    else
    {
        NSLog(@"Registered: %@", [c registeredHotKeys]);
    }
	[c release];
    
    // Insert code here to initialize your application
    self.dbPath = @"";
    self.keyPath = @"";
    self.intervalClip = [NSNumber numberWithInt:INTERVAL_CLEAR_CLIP_SECONDS];
    self.intervalPass = [NSNumber numberWithInt:INTERVAL_PASSWORD_MINUTES];
    
    //read user defaults
    //see /Users/taco/Library/Preferences/0catac0.MaKeePass.plist
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:@"maKeePassDB"] != nil)
    {
        self.dbPath = [userDefaults objectForKey:@"maKeePassDB"];
    }
    
    if([userDefaults objectForKey:@"maKeePassKey"] != nil)
    {
        self.keyPath = [userDefaults objectForKey:@"maKeePassKey"];
    }
    
    if([userDefaults objectForKey:@"maKeePassTimeoutClipboard"] != nil)
    {
        self.intervalClip = [userDefaults objectForKey:@"maKeePassTimeoutClipboard"];
    }
    else
    {
        [userDefaults setObject:self.intervalClip forKey:@"maKeePassTimeoutClipboard"];
    }
    
    if([userDefaults objectForKey:@"maKeePassTimeoutPassword"] != nil)
    {
        self.intervalPass = [userDefaults objectForKey:@"maKeePassTimeoutPassword"];
    }
    else
    {
        [userDefaults setObject:self.intervalPass forKey:@"maKeePassTimeoutPassword"];
    }
    
    self.lastTime = [NSDate distantPast];
}

- (void) readDB
{
    
    NSString * password = [self input:self.dbPath defaultValue:@""];
    static NSStringEncoding passwordEncoding = NSUTF8StringEncoding;
    
    // Try and load the database with the cached password from the keychain
    KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password encoding:passwordEncoding keyfile:self.keyPath];
    
    //TODO: release silently after expiry
    if(kdbTree != nil)
       [kdbTree release];
    
       @try {
        kdbTree = [[KdbReaderFactory load:self.dbPath withPassword:kdbPassword] retain];
        
        //tree read was succesful so, save settings (path to db & path to key)
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.dbPath forKey:@"maKeePassDB"];
        [userDefaults setObject:self.keyPath forKey:@"maKeePassKey"];
        
        //activate the panel, after slight delay
        [self performSelector:@selector(togglePanel:) withObject:nil afterDelay:.5];
        
    } @catch (NSException * exception) {
        // TODO: what does the semantics of Objective C say about the state of the kdbTree variable
        // if the evaluation of the right hand side of the assignment above results in an exception?
        // Just to be sure:
        kdbTree = nil;
    }
    
    [kdbPassword release];
    [[NSApplication sharedApplication] hide:self];
    
}

- (void) hotkeyWithEvent:(NSEvent *)hkEvent
{
    NSLog(@"hot key!");
    [self togglePanel:self];
}

//recursive search through tree
- (void)searchGroup:(KdbGroup*)group searchText:(NSString*)searchText results:(NSMutableArray*)results {
    for (KdbEntry *entry in group.entries) {
        NSRange range = [entry.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            [results addObject:entry];
        }
    }
    for (KdbGroup *g in group.groups) {
        [self searchGroup:g searchText:searchText results:results];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSLog(@"should terminate");
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    NSDate * now = [NSDate date];
    NSTimeInterval minutesElapsed = [now timeIntervalSinceDate:self.lastTime] / 60;
    self.lastTime = now;
    
    NSLog(@"Now recording time: %@", self.lastTime);

    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;

    if (self.panelController.hasActivePanel && (minutesElapsed > self.intervalPass.intValue)) {
        NSLog(@"%f minutes elapsed -- asking password again ",minutesElapsed);
        // get focus
        [[NSRunningApplication currentApplication] activateWithOptions:0];
        // ask password again.
        [self readDB];
    }

}

- (void) openWithConfiguration
{
    [self togglePanel:nil];
    [self.panelController performSelector:@selector(toggleConfiguration:) withObject:nil afterDelay:.3];
}


#pragma mark - Public accessors

- (PanelController *)panelController
{
    if (panelController == nil) {
        panelController = [[PanelController alloc] initWithDelegate:self];
        [panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end

