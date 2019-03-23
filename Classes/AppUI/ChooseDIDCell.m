//
//  ChooseDIDCell.m
//  linphone
//
//  Created by admin on 3/13/19.
//

#import "ChooseDIDCell.h"

@implementation ChooseDIDCell
@synthesize lbDIDNumber, lbTitle;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    lbTitle.font = lbDIDNumber.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    lbTitle.textColor = lbDIDNumber.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    
    lbTitle.text = @"Gọi ra prefix";
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20.0);
        make.right.equalTo(self.mas_centerX);
        make.top.bottom.equalTo(self);
    }];
    
    [lbDIDNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_centerX);
        make.right.equalTo(self).offset(-20.0);
        make.top.bottom.equalTo(self);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
