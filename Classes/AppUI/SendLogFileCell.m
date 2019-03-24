//
//  SendLogFileCell.m
//  linphone
//
//  Created by lam quang quan on 11/27/18.
//

#import "SendLogFileCell.h"

@implementation SendLogFileCell
@synthesize lbName, imgSelect;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    float hICon = 28.0;
    lbName.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    if (SCREEN_WIDTH == 320) {
        hICon = 24.0;
        lbName.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:16.0];
    }
    
    [imgSelect mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.right.equalTo(self).offset(-10.0);
        make.width.height.mas_equalTo(hICon);
    }];
    
    lbName.textColor = [UIColor colorWithRed:(80/255.0) green:(80/255.0)
                                        blue:(80/255.0) alpha:1.0];
    [lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self).offset(10.0);
        make.right.equalTo(imgSelect.mas_left).offset(-10.0);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
