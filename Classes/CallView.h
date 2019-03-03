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
#import "PulsingHaloLayer.h"

typedef enum typeCall{
    callIncoming,
    callOutgoing,
}typeCall;

@class VideoView;

@interface CallView : TPMultiLayoutViewController <UIGestureRecognizerDelegate, UICompositeViewDelegate, CAAnimationDelegate> {
  @private
	UITapGestureRecognizer *singleFingerTap;
	NSTimer *hideControlsTimer;
	BOOL videoHidden;
	VideoZoomHandler *videoZoomHandler;
}

@property (weak, nonatomic) IBOutlet UIImageView *bgCall;

@property (weak, nonatomic) IBOutlet UILabel *lbPhoneNumber;

@property(nonatomic, strong) IBOutlet CallPausedTableView *pausedCallsTable;
@property(weak, nonatomic) IBOutlet UIView *callView;

@property(nonatomic, strong) IBOutlet UIButton *optionsConferenceButton;

@property(nonatomic, strong) IBOutlet UIToggleButton *routesButton;
@property(nonatomic, strong) IBOutlet UIToggleButton *optionsButton;
@property(nonatomic, strong) IBOutlet UIHangUpButton *hangupButton;
@property(nonatomic, strong) IBOutlet UIView *routesView;
@property(nonatomic, strong) IBOutlet UIView *optionsView;
@property(nonatomic, strong) IBOutlet UIButton *routesEarpieceButton;
@property(nonatomic, strong) IBOutlet UIButton *routesBluetoothButton;
@property(nonatomic, strong) IBOutlet UIButton *optionsAddButton;
@property(weak, nonatomic) IBOutlet UIBouncingView *chatNotificationView;
@property(weak, nonatomic) IBOutlet UILabel *chatNotificationLabel;

@property(weak, nonatomic) IBOutlet UIView *bottomBar;
@property(weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *durationLabel;
@property(weak, nonatomic) IBOutlet UIView *pausedByRemoteView;

@property(strong, nonatomic) IBOutlet CallPausedTableView *conferenceCallsTable;

- (IBAction)onRoutesClick:(id)sender;
- (IBAction)onRoutesBluetoothClick:(id)sender;
- (IBAction)onRoutesEarpieceClick:(id)sender;
- (IBAction)onRoutesSpeakerClick:(id)sender;
- (IBAction)onOptionsClick:(id)sender;
- (IBAction)onOptionsTransferClick:(id)sender;
- (IBAction)onOptionsAddClick:(id)sender;
- (IBAction)onOptionsConferenceClick:(id)sender;
- (IBAction)onNumpadClick:(id)sender;
- (IBAction)onChatClick:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *_lbQuality;

@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, weak) PulsingHaloLayer *halo;

@end
