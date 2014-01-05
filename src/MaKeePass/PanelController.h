#import "BackgroundView.h"
#import "StatusItemView.h"
#import "ConfigView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
    BackgroundView *_backgroundView;
    ConfigView *_configView;
    id<PanelControllerDelegate> _delegate;
    NSSearchField *_searchField;
    NSTextField *_textField;
}

@property (nonatomic, assign) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, assign) IBOutlet NSSearchField *searchField;
@property (nonatomic, assign) IBOutlet NSTextField *textField;
@property (nonatomic, assign) ConfigView *configView;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (NSRect)statusRectForWindow:(NSWindow *)window;
-(IBAction)toggleConfiguration:(id)sender;

@end
