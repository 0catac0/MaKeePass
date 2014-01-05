#define STATUS_ITEM_VIEW_WIDTH 24.0

#pragma mark -

@class StatusItemView;

@interface MenubarController : NSObject {
@private
    StatusItemView *_statusItemView;
}

@property (nonatomic) BOOL hasActiveIcon;
@property (nonatomic, retain, readonly) NSStatusItem *statusItem;
@property (nonatomic, retain, readonly) StatusItemView *statusItemView;

@end
