//
//  HZTableViewPopup.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZGenericPopup.h"

typedef enum HZTableViewPopupConfiguration: NSInteger {
    HZTableViewPopupConfigurationTinyFooter,
    HZTableViewPopupConfigurationStandardFooter,
    HZTableViewPopupConfigurationStandardFooterWithClose
} HZTableViewPopupConfiguration;

@interface HZTableViewPopup : HZGenericPopup <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) UIImageView *header;
/** The `UILabel` centered on the header. By default, it uses a clear background color, white text color, and the bold system font with size 18 pts. While this property is readonly, its own properties are readwrite.  */
@property (nonatomic, strong, readonly) UILabel *headerLabel;
//@property (nonatomic, strong, readonly) UIImageView *footer;
@property (nonatomic, strong) UIView *footer;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *behindTableView;
@property (nonatomic, strong) UIView *aboveFooter;

@property (nonatomic) BOOL tinyFooter;

@end
