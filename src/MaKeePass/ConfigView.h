//
//  ConfigView.h
//  MaKeePass
//
//  Created by Taco van Dijk on 9/24/12.
//  Copyright (c) 2012 Waag Society. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConfigView : NSView
{
    NSTextField * dbLabel;
    NSTextField * keyLabel;
}

@property (nonatomic,retain) NSTextField * dbLabel;
@property (nonatomic,retain) NSTextField * keyLabel;

@end
