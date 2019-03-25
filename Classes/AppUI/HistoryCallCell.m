//
//  HistoryCallCell.m
//  linphone
//
//  Created by Ei Captain on 3/1/17.
//
//

#import "HistoryCallCell.h"

@implementation HistoryCallCell
@synthesize _cbDelete, _imgAvatar, _imgStatus, _lbName, _btnCall, _lbSepa, _lbPhone, lbDate, lbMissed;
@synthesize _phoneNumber;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    float wAvatar = 50.0;
    float wIconCall = 42.0;
    UIEdgeInsets edge = UIEdgeInsetsMake(7, 7, 7, 7);
    float marginRight = 10.0;
    float wNotif = 18.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        wAvatar = 40.0;
        wIconCall = 38.0;
        edge = UIEdgeInsetsMake(7, 7, 7, 7);
        marginRight = 2.0;
        wNotif = 15.0;
    }
    
    _lbName.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
    _lbPhone.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    _lbTime.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    lbDate.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    
    UIColor *textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    
    _imgAvatar.clipsToBounds = YES;
    _imgAvatar.layer.borderColor = [UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                    blue:(70/255.0) alpha:1.0].CGColor;
    _imgAvatar.layer.borderWidth = 1.0;
    _imgAvatar.layer.cornerRadius = wAvatar/2;
    [_imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(wAvatar);
    }];
    
    lbMissed.backgroundColor = UIColor.redColor;
    lbMissed.clipsToBounds = YES;
    lbMissed.layer.cornerRadius = wNotif/2;
    [lbMissed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_imgAvatar.mas_right).offset(-wNotif);
        make.top.equalTo(_imgAvatar).offset(0);
        make.width.height.mas_equalTo(wNotif);
    }];
    lbMissed.font = [UIFont systemFontOfSize: 12.0];
    lbMissed.textColor = UIColor.whiteColor;
    lbMissed.textAlignment = NSTextAlignmentCenter;
    
    _btnCall.imageEdgeInsets = edge;
    [_btnCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-marginRight);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(wIconCall);
    }];
    
    lbDate.textColor = textColor;
    [lbDate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar.mas_top);
        make.right.equalTo(_btnCall.mas_left).offset(-5.0);
        make.bottom.equalTo(_imgAvatar.mas_centerY);
        make.width.mas_equalTo(90.0);
    }];
    
    _lbTime.textColor = textColor;
    [_lbTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbDate.mas_bottom);
        make.left.right.equalTo(lbDate);
        make.bottom.equalTo(_imgAvatar.mas_bottom);
    }];
    
    _lbName.textColor = textColor;
    [_lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar);
        make.left.equalTo(_imgAvatar.mas_right).offset(5.0);
        make.bottom.equalTo(_imgAvatar.mas_centerY);
        make.right.equalTo(lbDate.mas_left).offset(-5.0);
    }];
    
    _imgStatus.clipsToBounds = YES;
    _imgStatus.layer.cornerRadius = wNotif/2;
    _imgStatus.layer.borderColor = UIColor.whiteColor.CGColor;
    _imgStatus.layer.borderWidth = 1.0;
    
    [_imgStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_lbTime.mas_centerY);
        make.left.equalTo(_lbName);
        make.width.height.mas_equalTo(wNotif);
    }];

    
    _lbPhone.textColor = textColor;
    [_lbPhone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lbName.mas_bottom);
        make.left.equalTo(_imgStatus.mas_right).offset(3.0);
        make.right.equalTo(_lbName);
        make.bottom.equalTo(_imgAvatar.mas_bottom);
    }];
    
    _lbSepa.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0)
                                               blue:(235/255.0) alpha:1.0];
    [_lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.height.mas_equalTo(1.0);
    }];
    
//    UIColor *cbColor = [UIColor colorWithRed:(17/255.0) green:(186/255.0)
//                                        blue:(153/255.0) alpha:1.0];
    UIColor *cbColor = UIColor.redColor;
    _cbDelete.lineWidth = 1.0;
    _cbDelete.boxType = BEMBoxTypeCircle;
    _cbDelete.onAnimationType = BEMAnimationTypeStroke;
    _cbDelete.offAnimationType = BEMAnimationTypeStroke;
    _cbDelete.tintColor = cbColor;
    _cbDelete.onTintColor = cbColor;
    _cbDelete.onFillColor = cbColor;
    _cbDelete.onCheckColor = UIColor.whiteColor;
    [_cbDelete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(24.0);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                blue:(240/255.0) alpha:1];
    }else{
        self.backgroundColor = UIColor.clearColor;
    }
}

- (void)updateFrameForHotline: (BOOL)isHotline {
    if (isHotline) {
        [_lbName mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_imgAvatar);
            make.left.equalTo(_imgAvatar.mas_right).offset(5);
            make.right.equalTo(_lbTime.mas_left).offset(-5);
        }];
    }else{
        [_lbName mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_imgAvatar).offset(4);
            make.left.equalTo(_imgAvatar.mas_right).offset(5);
            make.bottom.equalTo(_imgAvatar.mas_centerY);
            make.right.equalTo(_lbTime.mas_left).offset(-5);
        }];
    }
}

@end
