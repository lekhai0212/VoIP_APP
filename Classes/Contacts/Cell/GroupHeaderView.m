//
//  GroupHeaderView.m
//  linphone
//
//  Created by admin on 5/16/19.
//

#import "GroupHeaderView.h"

@implementation GroupHeaderView
@synthesize lbTitle, tfSort, imgArrow, btnType, icSort, lbSort;

- (void)setupUIForView {
    icSort.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [icSort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-10.0);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(40.0);
    }];
    
    tfSort.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    float sizeText = [AppUtils getSizeWithText:tfSort.text withFont:tfSort.font].width + 30 + 10;
    
    tfSort.layer.cornerRadius = 5.0;
    tfSort.layer.borderWidth = 1.0;
    tfSort.layer.borderColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:1.0].CGColor;
    [tfSort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(icSort.mas_left).offset(-5.0);
        make.centerY.equalTo(self.mas_centerY);
        make.height.mas_equalTo(38.0);
        make.width.mas_equalTo(sizeText);
    }];
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0, 38.0)];
    tfSort.leftView = leftView;
    tfSort.leftViewMode = UITextFieldViewModeAlways;
    
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 38.0)];
    tfSort.rightView = rightView;
    tfSort.rightViewMode = UITextFieldViewModeAlways;
    
    [imgArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(tfSort.mas_right).offset(-5.0);
        make.centerY.equalTo(tfSort.mas_centerY);
        make.width.height.mas_equalTo(14.0);
    }];
    
    [btnType setTitle:@"" forState:UIControlStateNormal];
    [btnType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(tfSort);
    }];
    
    lbTitle.text = @"";
    lbTitle.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(15.0);
        make.right.equalTo(tfSort.mas_left).offset(-5.0);
        make.top.bottom.equalTo(tfSort);
    }];
    
    lbTitle.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
}

- (IBAction)icSortClick:(UIButton *)sender {
}

- (IBAction)btnTypePress:(UIButton *)sender {
}
@end
