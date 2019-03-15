//
//  ChooseRingToneCell.m
//  linphone
//
//  Created by lam quang quan on 3/15/19.
//

#import "ChooseRingToneCell.h"

@implementation ChooseRingToneCell
@synthesize imgRingTone, lbName, imgSelected, lbSepa;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    [imgRingTone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(22.0);
    }];
    
    [imgSelected mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-20.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(22.0);
    }];
    
    lbName.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    lbName.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imgRingTone.mas_right).offset(20.0);
        make.right.equalTo(imgSelected.mas_left).offset(-20.0);
        make.top.bottom.equalTo(self);
    }];
    
    lbSepa.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.0];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(1.0);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
