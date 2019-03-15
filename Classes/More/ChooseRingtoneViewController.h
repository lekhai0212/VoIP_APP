//
//  ChooseRingtoneViewController.h
//  linphone
//
//  Created by lam quang quan on 3/14/19.
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"

@interface ChooseRingtoneViewController : UIViewController<UICompositeViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIImageView *bgHeader;
@property (weak, nonatomic) IBOutlet UIButton *iconBack;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UITableView *tbList;

- (IBAction)iconBackClick:(UIButton *)sender;

@end
