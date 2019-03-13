/* DialerViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "UICamSwitch.h"
#import "UICallButton.h"
#import "UIDigitButton.h"
#import "SearchContactPopupView.h"
#import "WebServices.h"

@class UICallButton;
@interface DialerView
	: TPMultiLayoutViewController <UITextFieldDelegate, UICompositeViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate, UICallButtonDelegate, UIAlertViewDelegate, UITextViewDelegate, SearchContactPopupViewDelegate, WebServicesDelegate> {
}


@property(nonatomic, strong) IBOutlet UICallButton *callButton;
@property(weak, nonatomic) IBOutlet UIIconButton *backspaceButton;

@property(nonatomic, strong) IBOutlet UIDigitButton *oneButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *twoButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *threeButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *fourButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *fiveButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *sixButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *sevenButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *eightButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *nineButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *starButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *zeroButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *hashButton;
@property(weak, nonatomic) IBOutlet UIView *padView;
@property (weak, nonatomic) IBOutlet UILabel *lbSepa123;
@property (weak, nonatomic) IBOutlet UILabel *lbSepa456;
@property (weak, nonatomic) IBOutlet UILabel *lbSepa789;
@property (weak, nonatomic) IBOutlet UICallButton *btnVideoCall;

- (IBAction)btnVideoCallPress:(UIButton *)sender;
- (IBAction)onAddressChange:(id)sender;
- (IBAction)onBackspaceClick:(id)sender;

- (void)setAddress:(NSString *)address;

@property (weak, nonatomic) IBOutlet UIView *_viewNumber;
@property(nonatomic, strong) IBOutlet UITextField *addressField;

@property (weak, nonatomic) IBOutlet UIView *_viewStatus;
@property (weak, nonatomic) IBOutlet UIImageView *_imgLogoSmall;
@property (weak, nonatomic) IBOutlet UILabel *_lbAccount;
@property (weak, nonatomic) IBOutlet UILabel *_lbStatus;

- (IBAction)_btnNumberPressed:(id)sender;
- (IBAction)_btnCallPressed:(UIButton *)sender;

@end
