//
//  ConfigView.m
//  MaKeePass
//
//  Created by Taco van Dijk on 9/24/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "ConfigView.h"
#import "AppDelegate.h"

#define FILL_OPACITY 0.9f

@implementation ConfigView
@synthesize dbLabel;
@synthesize keyLabel;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    NSTextField * adbLabel = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(10, 50, 150, 20))];
    [adbLabel setStringValue:[(AppDelegate*)[NSApplication sharedApplication].delegate dbPath]];//TODO: get what is currently selected
    //[adbLabel sizeToFit];
    [adbLabel setEditable:false];
    [adbLabel setBordered:NO];
    [self addSubview:adbLabel];
    
    NSButton * dbSelectButton = [[NSButton alloc] initWithFrame:NSRectFromCGRect(CGRectMake(adbLabel.frame.origin.x + adbLabel.bounds.size.width + 5, adbLabel.frame.origin.y, 20,adbLabel.bounds.size.height))];
    [dbSelectButton setTitle:@"..."];
    [self addSubview:dbSelectButton];
    
    NSTextField * aKeyLabel = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(10, 20, 150, 20))];
    [aKeyLabel setStringValue:[(AppDelegate*)[NSApplication sharedApplication].delegate keyPath]];//TODO: get what is currently selected
    //[aKeyLabel sizeToFit];
    [aKeyLabel setEditable:false];
    [aKeyLabel setBordered:NO];
    [self addSubview:aKeyLabel];
    
    NSButton * keySelectButton = [[NSButton alloc] initWithFrame:NSRectFromCGRect(CGRectMake(aKeyLabel.frame.origin.x + aKeyLabel.bounds.size.width + 5, aKeyLabel.frame.origin.y, 20,aKeyLabel.bounds.size.height))];
    [keySelectButton setTitle:@"..."];
    [self addSubview:keySelectButton];
    
    [keySelectButton setTarget:self];
    [keySelectButton setAction:@selector(pickKeyFile:)];
    
    [dbSelectButton setTarget:self];
    [dbSelectButton setAction:@selector(pickDatabaseFile:)];
    
    self.dbLabel = adbLabel;
    self.keyLabel = aKeyLabel;
    
    [dbSelectButton release];
    [adbLabel release];
    [aKeyLabel release];
    [keySelectButton release];
    
    return self;
}

-(void) viewDidUnhide
{
   //update the current values
    NSString * keyName = [[(AppDelegate*)[NSApplication sharedApplication].delegate keyPath] lastPathComponent];
    NSString * dbName =[[(AppDelegate*)[NSApplication sharedApplication].delegate dbPath] lastPathComponent];
    
    [self.keyLabel setStringValue:keyName];
    [self.dbLabel setStringValue:dbName];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Fill in background Color
    CGRect inset = CGRectInset(NSRectToCGRect(dirtyRect), 0, 10);
    CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
    //CGContextSetRGBFillColor(context, 1,1,1,0.8);
    CGContextSetFillColorWithColor(context, [[NSColor colorWithDeviceWhite:1 alpha:FILL_OPACITY] CGColor]);
    CGContextFillRect(context, inset);
    
    //TODO add config fields / pickers

    
}

//successfully picking a key file kicks of asking the new password
-(void)pickKeyFile:(id)sender
{
    [[NSApplication sharedApplication] hideOtherApplications:self];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            // do something with the url here.
            
            [(AppDelegate*)[NSApplication sharedApplication].delegate setKeyPath:[url path]];
           //[((AppDelegate*)[NSApplication sharedApplication].delegate) openWithConfiguration];//go back to this state
            [(AppDelegate*)[NSApplication sharedApplication].delegate readDB];
        }
    }
}

-(void)pickDatabaseFile:(id)sender
{
    [[NSApplication sharedApplication] hideOtherApplications:self];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            // do something with the url here.
            [(AppDelegate*)[NSApplication sharedApplication].delegate setDbPath:[url path]];
            [((AppDelegate*)[NSApplication sharedApplication].delegate) openWithConfiguration];//go back to this state
            
        }
    }
}

@end
