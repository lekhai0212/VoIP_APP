//
//  RecordAudioCallCell.m
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import "RecordAudioCallCell.h"

@implementation RecordAudioCallCell
@synthesize btnPlay, lbName, btnChoose, lbSepa;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    //  btnPlay.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    [btnPlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).mas_offset(10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(40.0);
    }];
    
    [btnChoose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).mas_offset(-10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(40.0);
    }];
    
    lbName.backgroundColor = UIColor.orangeColor;
    lbName.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    [lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.top.equalTo(self);
        make.left.equalTo(btnPlay.mas_right).offset(5.0);
        make.right.equalTo(btnChoose.mas_left).offset(-5.0);
    }];
    ssss
    lbSepa.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                              blue:(240/255.0) alpha:1.0];
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
