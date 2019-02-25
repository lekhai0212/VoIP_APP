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
@synthesize iconBack, iconMiniKeypadEndCall, tfNumber, lbQualityValue, viewKeypad, bgCall;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setupUIForView {
    //  Number keypad
    NSString *modelName = [DeviceUtils getModelsOfCurrentDevice];
    float wIcon = [DeviceUtils getSizeOfKeypadButtonForDevice: modelName];
    float spaceMarginY = [DeviceUtils getSpaceYBetweenKeypadButtonsForDevice: modelName];
    float spaceMarginX = [DeviceUtils getSpaceXBetweenKeypadButtonsForDevice: modelName];
    
    [bgCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self);
    }];
    
    [iconMiniKeypadEndCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.bottom.equalTo(self).offset(-20);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.left.equalTo(self);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    [lbQualityValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(iconBack);
        make.left.equalTo(iconBack.mas_right).offset(10);
        make.right.equalTo(self).offset(-10-HEADER_ICON_WIDTH);
    }];
    
    [tfNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbQualityValue.mas_bottom).offset(20);
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
        make.left.right.equalTo(self);
        make.top.equalTo(tfNumber.mas_bottom).offset(10);
        make.bottom.equalTo(iconMiniKeypadEndCall.mas_top).offset(-10);
    }];
    
    
    [fiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewKeypad.mas_centerX);
        make.bottom.equalTo(viewKeypad.mas_centerY).offset(-spaceMarginY/2);
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
    
    [eightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(fiveButton.mas_bottom).offset(spaceMarginY);
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
}

- (IBAction)onDigitPress:(UIDigitButton *)sender {
    NSString *value = [NSString stringWithFormat:@"%c", sender.digit];
    tfNumber.text = [NSString stringWithFormat:@"%@%@", tfNumber.text, value];
}

@end
