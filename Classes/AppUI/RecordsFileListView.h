//
//  RecordsFileListView.h
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import <UIKit/UIKit.h>

@interface RecordsFileListView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIImageView *bgHeader;
@property (weak, nonatomic) IBOutlet UIButton *icBack;
@property (weak, nonatomic) IBOutlet UILabel *lbHeader;
@property (weak, nonatomic) IBOutlet UIButton *icSend;

@property (weak, nonatomic) IBOutlet UITableView *tbList;
@property (strong, nonatomic) NSMutableArray *listRecords;
@property (assign, nonatomic) float hCell;

- (void)setupUIForView;
- (void)reloadDataForView;

@end
