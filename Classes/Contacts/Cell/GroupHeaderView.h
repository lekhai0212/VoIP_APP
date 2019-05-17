//
//  GroupHeaderView.h
//  linphone
//
//  Created by admin on 5/16/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupHeaderView : UIView
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UITextField *tfSort;
@property (weak, nonatomic) IBOutlet UIButton *btnType;
@property (weak, nonatomic) IBOutlet UIButton *icSort;
@property (weak, nonatomic) IBOutlet UIImageView *imgArrow;
@property (weak, nonatomic) IBOutlet UILabel *lbSort;

- (IBAction)icSortClick:(UIButton *)sender;
- (IBAction)btnTypePress:(UIButton *)sender;

- (void)setupUIForView;

@end

NS_ASSUME_NONNULL_END
