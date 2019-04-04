/* InCallViewController.h
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

#import "VideoZoomHandler.h"
#import "UICamSwitch.h"

#import "UICompositeView.h"
#import "CallPausedTableView.h"

#import "UIMutedMicroButton.h"
#import "UIPauseButton.h"
#import "UISpeakerButton.h"
#import "UIVideoButton.h"
#import "UIHangUpButton.h"
#import "UIDigitButton.h"
#import "UIRoundedImageView.h"
#import "UIBouncingView.h"
#import "MarqueeLabel.h"

typedef enum typeCall{
    callIncoming,
    callOutgoing,
}typeCall;

@class VideoView;

@interface CallView : TPMultiLayoutViewController <UIGestureRecognizerDelegate, UICompositeViewDelegate, UISpeakerButtonDelegate, UIMutedMicroButtonDelegate, UIPauseButtonDelegate> {
  @private
	UITapGestureRecognizer *singleFingerTap;
	NSTimer *hideControlsTimer;
	NSTimer *videoDismissTimer;
	BOOL videoHidden;
	VideoZoomHandler *videoZoomHandler;
}


@property (weak, nonatomic) IBOutlet UIImageView *bgAudioCall;
@property(weak, nonatomic) IBOutlet MarqueeLabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lbPhoneNumber;
@property(weak, nonatomic) IBOutlet UILabel *durationLabel;
@property(weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *_lbQuality;
@property(nonatomic, strong) IBOutlet UIButton *speakerButton;
@property(nonatomic, strong) IBOutlet UIHangUpButton *hangupButton;
@property(nonatomic, strong) IBOutlet UIButton *microButton;
@property(nonatomic, strong) IBOutlet UIPauseButton *callPauseButton;
@property(nonatomic, strong) IBOutlet UIToggleButton *numpadButton;
- (IBAction)speakerButtonPress:(UIButton *)sender;
- (IBAction)microButtonPress:(UIButton *)sender;

//  Video call view
@property (weak, nonatomic) IBOutlet UIView *viewVideoCall;
@property(nonatomic, strong) IBOutlet UIView *videoView;
@property(nonatomic, strong) IBOutlet UIView *videoPreview;
@property (weak, nonatomic) IBOutlet UILabel *lbVideoQuality;
@property (weak, nonatomic) IBOutlet UILabel *_lbVideoTime;
@property (weak, nonatomic) IBOutlet MarqueeLabel *lbAddressVideoCall;
@property (weak, nonatomic) IBOutlet UIButton *btnMicroVideo;
@property (weak, nonatomic) IBOutlet UIButton *btnSpeakerVideo;
@property (weak, nonatomic) IBOutlet UIButton *btnOffCamera;
@property (weak, nonatomic) IBOutlet UICamSwitch *btnSwitchCamera;
@property (weak, nonatomic) IBOutlet UIToggleButton *btnKeypadVideo;
@property (weak, nonatomic) IBOutlet UIHangUpButton *btnHangupVideo;

- (IBAction)btnMicroVideoClick:(id)sender;
- (IBAction)btnSpeakerVideoClick:(id)sender;
- (IBAction)btnOffCameraClick:(UIButton *)sender;
- (IBAction)btnSwitchCameraClick:(id)sender;
- (IBAction)btnKeypadVideoClick:(id)sender;
- (IBAction)btnHangupVideoClick:(id)sender;











@property(nonatomic, strong) IBOutlet CallPausedTableView *pausedCallsTable;


@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *videoWaitingForFirstImage;
@property(weak, nonatomic) IBOutlet UIView *callView;


@property(nonatomic, strong) IBOutlet UIButton *optionsConferenceButton;

@property(nonatomic, strong) IBOutlet UIToggleButton *routesButton;
@property(nonatomic, strong) IBOutlet UIToggleButton *optionsButton;

@property(nonatomic, strong) IBOutlet UIView *numpadView;
@property(nonatomic, strong) IBOutlet UIView *routesView;
@property(nonatomic, strong) IBOutlet UIView *optionsView;
@property(nonatomic, strong) IBOutlet UIButton *routesEarpieceButton;

@property(nonatomic, strong) IBOutlet UIButton *routesBluetoothButton;
@property(nonatomic, strong) IBOutlet UIButton *optionsAddButton;



@property(weak, nonatomic) IBOutlet UIBouncingView *chatNotificationView;
@property(weak, nonatomic) IBOutlet UILabel *chatNotificationLabel;

@property(weak, nonatomic) IBOutlet UIView *bottomBar;
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


@property(strong, nonatomic) IBOutlet CallPausedTableView *conferenceCallsTable;

- (IBAction)onRoutesClick:(id)sender;
- (IBAction)onRoutesBluetoothClick:(id)sender;
- (IBAction)onRoutesEarpieceClick:(id)sender;
- (IBAction)onRoutesSpeakerClick:(id)sender;
- (IBAction)onOptionsClick:(id)sender;
- (IBAction)onOptionsTransferClick:(id)sender;
- (IBAction)onOptionsAddClick:(id)sender;
- (IBAction)onOptionsConferenceClick:(id)sender;
- (IBAction)onChatClick:(id)sender;

@property (nonatomic, strong) NSTimer *durationTimer;


@end
