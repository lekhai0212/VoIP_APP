//
//  PBXHeaderView.m
//  linphone
//
//  Created by admin on 5/18/19.
//

#import "PBXHeaderView.h"
#import "CustomTextAttachment.h"

@implementation PBXHeaderView
@synthesize lbTitle, btnSync, lbSortType, tfSort, imgArrow, icSort, btnSortType;
@synthesize delegate;

- (void)setupUIForView {
    self.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                            blue:(240/255.0) alpha:1.0];
    
    lbTitle.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
    lbTitle.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(15.0);
        make.top.equalTo(self).offset(5.0);
        make.height.mas_equalTo(35.0);
        make.right.equalTo(self.mas_centerX).offset(50);
    }];
    
    [btnSync setAttributedTitle:[self getSyncTitleContentWithFont:[LinphoneAppDelegate sharedInstance].contentFontBold andSizeIcon:17.0] forState:UIControlStateNormal];
    [btnSync mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15.0);
        make.top.bottom.equalTo(lbTitle);
        make.left.equalTo(lbTitle.mas_right);
    }];
    
    lbSortType.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    lbSortType.textColor = [UIColor colorWithRed:(100/255.0) green:(100/255.0) blue:(100/255.0) alpha:1.0];
    float sizeText = [AppUtils getSizeWithText:lbSortType.text withFont:lbSortType.font].width + 10.0;
    
    [lbSortType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lbTitle);
        make.top.equalTo(lbTitle.mas_bottom);
        make.width.mas_equalTo(sizeText);
        make.height.mas_equalTo(35.0);
    }];
    
    tfSort.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    
    sizeText = [AppUtils getSizeWithText:tfSort.text withFont:tfSort.font].width + 10 + 25.0;
    [tfSort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lbSortType.mas_right);
        make.centerY.equalTo(lbSortType.mas_centerY);
        make.width.mas_equalTo(sizeText);
        make.height.mas_equalTo(30.0);
    }];
    
    [btnSortType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(tfSort);
    }];
    
    [imgArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(tfSort.mas_right).offset(-3.0);
        make.centerY.equalTo(tfSort.mas_centerY);
        make.width.height.mas_equalTo(14.0);
    }];
    
    icSort.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [icSort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10.0);
        make.top.bottom.equalTo(lbSortType);
        make.width.mas_equalTo(35.0);
    }];
}

- (IBAction)btnSortTypePress:(UIButton *)sender {
}

- (IBAction)btnSyncPress:(UIButton *)sender {
    [delegate onSyncButtonPress];
}

- (IBAction)icSortClick:(UIButton *)sender {
    [delegate onIconSortClick];
}

- (NSAttributedString *)getSyncTitleContentWithFont: (UIFont *)textFont andSizeIcon: (float)size
{
    CustomTextAttachment *attachment = [[CustomTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"sync.png"];
    [attachment setImageHeight: size];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] initWithString:@"  Đồng bộ"];
    [contentString addAttribute:NSFontAttributeName value:textFont range:NSMakeRange(0, contentString.length)];
    [contentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0] range:NSMakeRange(0, contentString.length)];
    
    NSMutableAttributedString *verString = [[NSMutableAttributedString alloc] initWithAttributedString: attachmentString];
    //
    [verString appendAttributedString: contentString];
    return verString;
}

@end
