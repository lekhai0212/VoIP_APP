//
//  UIMiniKeypad.m
//  linphone
//
//  Created by user on 18/12/13.
//
//

#import "UIMiniKeypad.h"

@implementation UIMiniKeypad
@synthesize oneButton;
@synthesize twoButton;
@synthesize threeButton;
@synthesize fourButton;
@synthesize fiveButton;
@synthesize sevenButton;
@synthesize sixButton;
@synthesize eightButton;
@synthesize nineButton;
@synthesize zeroButton;
@synthesize sharpButton;
@synthesize starButton;
@synthesize iconBack, iconMiniKeypadEndCall, tfNumber, viewKeypad, lbSepa123, lbSepa456, lbSepa789;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setupUIForView {
    self.backgroundColor = UIColor.whiteColor;
    
    //  Number keypad
    NSString *modelName = [DeviceUtils getModelsOfCurrentDevice];
    
    float wIcon = [DeviceUtils getSizeOfKeypadButtonForDevice: modelName];
    float spaceMarginY = [DeviceUtils getSpaceYBetweenKeypadButtonsForDevice: modelName];
    float spaceMarginX = [DeviceUtils getSpaceXBetweenKeypadButtonsForDevice: modelName];
    
    iconBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.left.equalTo(self);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    [tfNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iconBack.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(60.0);
    }];
    tfNumber.keyboardType = UIKeyboardTypePhonePad;
    tfNumber.enabled = NO;
    tfNumber.textAlignment = NSTextAlignmentCenter;
    tfNumber.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:45.0];
    tfNumber.adjustsFontSizeToFitWidth = YES;
    tfNumber.backgroundColor = UIColor.clearColor;
    tfNumber.textColor = UIColor.whiteColor;
    [tfNumber setBorderStyle: UITextBorderStyleNone];
    
    [viewKeypad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(tfNumber.mas_bottom);
    }];
    
    //  7   8   9
    [eightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(viewKeypad.mas_centerY);
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [sevenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(eightButton);
        make.right.equalTo(eightButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [nineButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(eightButton);
        make.left.equalTo(eightButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  4   5   6
    [fiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.bottom.equalTo(eightButton.mas_top).offset(-spaceMarginY);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [fourButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(fiveButton);
        make.right.equalTo(fiveButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [sixButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(fiveButton);
        make.left.equalTo(fiveButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  1   2   3
    [twoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(fiveButton.mas_top).offset(-spaceMarginY);
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [oneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(twoButton);
        make.right.equalTo(twoButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [threeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(twoButton);
        make.left.equalTo(twoButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  *   0   #
    [zeroButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(eightButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [starButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(zeroButton);
        make.right.equalTo(zeroButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [sharpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(zeroButton);
        make.left.equalTo(zeroButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [iconMiniKeypadEndCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.top.equalTo(zeroButton.mas_bottom).offset(spaceMarginY);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    lbSepa123.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                 blue:(240/255.0) alpha:1.0];
    lbSepa456.backgroundColor = lbSepa789.backgroundColor = lbSepa123.backgroundColor;
    
    [lbSepa123 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(oneButton);
        make.right.equalTo(threeButton.mas_right);
        make.top.equalTo(oneButton.mas_bottom).offset(spaceMarginY/2);
        make.height.mas_equalTo(1.0);
    }];
    
    [lbSepa456 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(fiveButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
    
    [lbSepa789 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(eightButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
}

- (IBAction)onDigitPress:(UIDigitButton *)sender {
    NSString *value = [NSString stringWithFormat:@"%c", sender.digit];
    tfNumber.text = [NSString stringWithFormat:@"%@%@", tfNumber.text, value];
}

@end
