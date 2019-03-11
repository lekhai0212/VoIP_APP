//
//  UIContactPhoneCell.m
//  linphone
//
//  Created by lam quang quan on 10/10/18.
//

#import "UIContactPhoneCell.h"

@implementation UIContactPhoneCell
@synthesize lbTitle, lbPhone, icCall, icVideoCall, lbSepa;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.contentView.backgroundColor = UIColor.whiteColor;
    if (SCREEN_WIDTH > 320) {
        lbTitle.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:17.0];
        lbPhone.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:19.0];
    }else{
        lbTitle.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:15.0];
        lbPhone.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:17.0];
    }
    
    [icCall setTitleColor:UIColor.clearColor forState:UIControlStateNormal];
    icCall.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [icCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(42.0);
    }];
    
    [icVideoCall setTitleColor:UIColor.clearColor forState:UIControlStateNormal];
    icVideoCall.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [icVideoCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(icCall.mas_left).offset(-10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.equalTo(icCall.mas_width);
        make.height.equalTo(icCall.mas_height);
    }];
    
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(5.0);
        make.bottom.equalTo(self.mas_centerY);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(icVideoCall.mas_left).offset(-10.0);
    }];
    lbTitle.textColor = [UIColor colorWithRed:(120/255.0) green:(120/255.0)
                                         blue:(120/255.0) alpha:1.0];
    
    [lbPhone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_centerY);
        make.left.right.equalTo(lbTitle);
        make.bottom.equalTo(self).offset(-5.0);
    }];
    lbPhone.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    
    if (IS_IPOD || IS_IPHONE) {
        [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(lbTitle);
            make.right.bottom.equalTo(self);
            make.height.mas_equalTo(1.0);
        }];
    }else{
        [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(1.0);
        }];
    }
    
    lbSepa.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0)
                                               blue:(235/255.0) alpha:1.0];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
