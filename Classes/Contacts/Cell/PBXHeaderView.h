//
//  PBXHeaderView.h
//  linphone
//
//  Created by admin on 5/18/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PBXHeaderViewDelegate
- (void)onIconSortClick;
- (void)onSyncButtonPress;
- (void)onSortTypeButtonPress;
@end

@interface PBXHeaderView : UIView
@property (nonatomic, strong) id<NSObject, PBXHeaderViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnSync;
@property (weak, nonatomic) IBOutlet UILabel *lbSortType;
@property (weak, nonatomic) IBOutlet UITextField *tfSort;
@property (weak, nonatomic) IBOutlet UIButton *icSort;
@property (weak, nonatomic) IBOutlet UIImageView *imgArrow;
@property (weak, nonatomic) IBOutlet UIButton *btnSortType;

- (IBAction)btnSyncPress:(UIButton *)sender;
- (IBAction)icSortClick:(UIButton *)sender;
- (void)setupUIForView ;
- (IBAction)btnSortTypePress:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
