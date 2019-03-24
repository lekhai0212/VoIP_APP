//
//  MenuCell.m
//  linphone
//
//  Created by Apple on 4/26/17.
//
//

#import "MenuCell.h"

@implementation MenuCell
@synthesize _iconImage, _lbTitle, _lbSepa, imgNext;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    float margin = 20.0;
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        _lbTitle.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:16.0];
        margin = 14.0;
        
    }else {
        _lbTitle.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
        
    }
    self.contentView.backgroundColor = UIColor.whiteColor;
    
    [_iconImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(margin);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(22.0);
    }];
    
    [imgNext mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-margin);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(17.0);
    }];
    
    
    _lbTitle.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    _lbTitle.numberOfLines = 10;
    [_lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_iconImage.mas_right).offset(10);
        make.right.equalTo(imgNext.mas_left).offset(-20);
        make.top.bottom.equalTo(self);
    }];
    
    _lbSepa.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                               blue:(240/255.0) alpha:1.0];
    [_lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.height.mas_equalTo(5.0);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                blue:(240/255.0) alpha:1.0];
    }else{
        self.backgroundColor = UIColor.clearColor;
    }
}

@end
