//
//  GroupHeaderView.m
//  linphone
//
//  Created by admin on 5/16/19.
//

#import "GroupHeaderView.h"

@implementation GroupHeaderView
@synthesize lbTitle, icSort, lbSepa;

- (void)setupUIForView {
    self.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                            blue:(240/255.0) alpha:1.0];
    
    icSort.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [icSort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(35.0);
    }];
    
    lbTitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(15.0);
        make.top.bottom.equalTo(icSort);
        make.right.equalTo(icSort.mas_left).offset(-5.0);
    }];
    
    lbSepa.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                              blue:(240/255.0) alpha:1.0];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(1.0);
    }];
    
    lbTitle.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
}

- (IBAction)icSortClick:(UIButton *)sender {
}

@end
