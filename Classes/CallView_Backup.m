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

#import <AVFoundation/AVAudioSession.h>
#import <AddressBook/AddressBook.h>
#import <AudioToolbox/AudioToolbox.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <UserNotifications/UserNotifications.h>

#import "CallView.h"
#import "MainChatViewController.h"
#import "CallSideMenuView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"

#include "linphone/linphonecore.h"

#import "NSData+Base64.h"
#import "UIConferenceCell.h"
#import "ContactDetailObj.h"
#import "UIMiniKeypad.h"

#import "NSDatabase.h"
#import "FooterVideoCallView.h"
#import "OTRMessage.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "UploadPicture.h"

void message_received(LinphoneCore *lc, LinphoneChatRoom *room, const LinphoneAddress *from, const char *message) {
    printf(" Message [%s] received from [%s] \n",message,linphone_address_as_string (from));
}

const NSInteger SECURE_BUTTON_TAG = 5;

@interface CallView (){
    LinphoneAppDelegate *appDelegate;
    UIFont *textFont;
    
    float wButton;
    float wCollection;
    float marginX;
    
    UIButton *btnConference;
    UIButton *buttonRecord;
    UIButton *buttonMessage;
    UIButton *buttonSendfile;
    UIButton *btnNumpad;
    
    int typeCurrentCall;
    BOOL changeConference;
    
    const MSList *list;
    
    UITapGestureRecognizer *tapOnVideoCall;
    
    NSTimer *updateTimeConf;
    
    NSMutableAttributedString *videoStateString;
    
    //  End call trong add keypad
    UIHangUpButton *btEndCall;
    UIButton *btHideKeypad;
    
    float hIconEndCall;
    FooterVideoCallView *videoCallFooterView;
    
    UIImageView *icVideoCall;
    UIImageView *icWaveVideo;
    UIImageView *icOffCameraForPreview;
    UILabel *lbMsgCount;
}

@end

@implementation CallView_Backup {
	BOOL hiddenVolume;
}
@synthesize _viewHeader, _icLogo, _lbQuality, _viewInfo, _lbState, _bgHeader, _viewCommand, _scrollView;
@synthesize detailConference, _bgHeaderConf, lbAddressConf, _lbConferenceDuration, btnAddCallConf, btnEndCallConf, avatarConference, collectionConference;
@synthesize viewVideoCall, _lbVideoTime, lbAddressVideoCall, lbStateVideoCall, iconCaptureScreen;
@synthesize durationTimer;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
	if (self != nil) {
		singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls:)];
		videoZoomHandler = [[VideoZoomHandler alloc] init];
		videoHidden = TRUE;
	}
	return self;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:nil
															   sideMenu:nil
															 fullscreen:false
														 isLeftFragment:YES
														   fragmentWith:nil];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	_routesEarpieceButton.enabled = !IPAD;

// TODO: fixme! video preview frame is too big compared to openGL preview
// frame, so until this is fixed, temporary disabled it.
#if 0
	_videoPreview.layer.borderColor = UIColor.whiteColor.CGColor;
	_videoPreview.layer.borderWidth = 1;
#endif
    
    
    tapOnVideoCall = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(whenTapOnVideoCall)];
    tapOnVideoCall.delegate = self;
    [viewVideoCall addGestureRecognizer: tapOnVideoCall];
    
    [tapOnVideoCall requireGestureRecognizerToFail: singleFingerTap];
    singleFingerTap.numberOfTapsRequired = 2;
    singleFingerTap.cancelsTouchesInView = NO;
	[viewVideoCall addGestureRecognizer:singleFingerTap];
	[videoZoomHandler setup: viewVideoCall];

	UIPanGestureRecognizer *dragndrop =
		[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveVideoPreview:)];
	dragndrop.minimumNumberOfTouches = 1;
	[_videoPreview addGestureRecognizer:dragndrop];

	[_zeroButton setDigit:'0'];
	[_zeroButton setDtmf:true];
	[_oneButton setDigit:'1'];
	[_oneButton setDtmf:true];
	[_twoButton setDigit:'2'];
	[_twoButton setDtmf:true];
	[_threeButton setDigit:'3'];
	[_threeButton setDtmf:true];
	[_fourButton setDigit:'4'];
	[_fourButton setDtmf:true];
	[_fiveButton setDigit:'5'];
	[_fiveButton setDtmf:true];
	[_sixButton setDigit:'6'];
	[_sixButton setDtmf:true];
	[_sevenButton setDigit:'7'];
	[_sevenButton setDtmf:true];
	[_eightButton setDigit:'8'];
	[_eightButton setDtmf:true];
	[_nineButton setDigit:'9'];
	[_nineButton setDtmf:true];
	[_starButton setDigit:'*'];
	[_starButton setDtmf:true];
	[_hashButton setDigit:'#'];
	[_hashButton setDtmf:true];
    
    //  Add ney by Khai Le on 09/11/2017
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [_speakerButton setHidden: YES];
}

- (void)dealloc {
	[PhoneMainView.instance.view removeGestureRecognizer:singleFingerTap];
	// Remove all observer
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    [self setupUIForView];
    
    //  Leo Kelvin
    [self addScrollview];
    _bottomBar.hidden = YES;
    _bottomBar.clipsToBounds = YES;
    
	LinphoneManager.instance.nextCallIsTransfer = NO;

    _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_good]];
    _nameLabel.text = @"";
    lbAddressConf.text = @"";

	// Update on show
	[self hideRoutes:TRUE animated:FALSE];
	[self hideOptions:TRUE animated:FALSE];
	[self hidePad:TRUE animated:FALSE];
	[self hideSpeaker:LinphoneManager.instance.bluetoothAvailable];
	[self callDurationUpdate];
	[self onCurrentCallChange];
	// Set windows (warn memory leaks)
	linphone_core_set_native_video_window_id(LC, (__bridge void *)(_videoView));
	linphone_core_set_native_preview_window_id(LC, (__bridge void *)(_videoPreview));

	[self previewTouchLift];
	// Enable tap
    singleFingerTap.enabled = YES;
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bluetoothAvailabilityUpdateEvent:)
											   name:kLinphoneBluetoothAvailabilityUpdate object:nil];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callEnded)
                                               name:@"callEnded" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(messageReceived:)
                                               name:kOTRMessageReceived object:nil];
    
	durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                   selector:@selector(callDurationUpdate)
                                                   userInfo:nil repeats:YES];
    
    //  Update address
    [self updateAddress];
    
    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
    NSLog(@"So cuoc goi: %d", count);
    
    /*--Khong co goi conference--*/
    if(count < 2 ){
        [self btnHideKeypadPressed];
        
        _callView.hidden = NO;
        _conferenceView.hidden = YES;
        viewVideoCall.hidden = YES;
        
        //  Leo Kelvin
        //  updateTime = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateCall) userInfo:nil repeats:YES];
    }else{
        _callView.hidden = YES;
        _conferenceView.hidden = NO;
        viewVideoCall.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIDevice.currentDevice.proximityMonitoringEnabled = YES;

	[PhoneMainView.instance setVolumeHidden:TRUE];
	hiddenVolume = TRUE;

	// we must wait didAppear to reset fullscreen mode because we cannot change it in viewwillappear
	LinphoneCall *call = linphone_core_get_current_call(LC);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state animated:FALSE];
}

- (void)testPressed {
    linphone_core_enable_chat(LC);
    
    LinphoneContent *content = linphone_core_create_content(LC);
    linphone_content_set_string_buffer(content, "KL");
    linphone_content_set_type(content, "text/plain");

    LinphoneInfoMessage *msg = linphone_core_create_info_message(LC);
    linphone_info_message_set_content(msg, content);

    LinphoneCall *call = linphone_core_get_current_call(LC);
    linphone_call_send_info_message(call, msg);
    [self.view makeToast:@"SEND LINPHONE INFO MESSAGE" duration:2.0 position:CSToastPositionCenter];
    
    //  NSString *username = USERNAME;
    NSString *phone = [self getPhoneNumberOfCall];
    NSString *uri;
    LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress: phone];
    if (addr) {
        uri = [NSString stringWithUTF8String:linphone_address_as_string(addr)];
    } else {
        uri = phone;
    }
    LinphoneChatRoom *chat_room = linphone_core_get_chat_room_from_uri(LC, uri.UTF8String);
    LinphoneChatMessage *msg1 = linphone_chat_room_create_message(chat_room, "LQK");
    linphone_chat_room_send_chat_message(chat_room, msg1);
    
    [self.view makeToast:@"SEND ROOM MESSAGE" duration:2.0 position:CSToastPositionCenter];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self disableVideoDisplay:TRUE animated:NO];

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}

	if (videoDismissTimer) {
		[self dismissVideoActionSheet:videoDismissTimer];
		[videoDismissTimer invalidate];
		videoDismissTimer = nil;
	}

	// Remove observer
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

    [lbMsgCount removeFromSuperview];
    
	[[UIApplication sharedApplication] setIdleTimerDisabled:false];
	UIDevice.currentDevice.proximityMonitoringEnabled = NO;

	[PhoneMainView.instance fullScreen:false];
	// Disable tap
	[singleFingerTap setEnabled:FALSE];

	if (linphone_core_get_calls_nb(LC) == 0) {
		// reseting speaker button because no more call
		_speakerButton.selected = FALSE;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self previewTouchLift];
	[self hideStatusBar:!videoHidden && (_nameLabel.alpha <= 0.f)];
}

#pragma mark - UI modification

- (void)hideSpinnerIndicator:(LinphoneCall *)call {
	_videoWaitingForFirstImage.hidden = TRUE;
}

static void hideSpinner(LinphoneCall *call, void *user_data) {
	CallView *thiz = (__bridge CallView *)user_data;
	[thiz hideSpinnerIndicator:call];
}

- (void)updateBottomBar:(LinphoneCall *)call state:(LinphoneCallState)state {
	//  [_speakerButton update];
	[_microButton update];
	//  [_callPauseButton update];
	[_conferencePauseButton update];
	[_videoButton update];
	[_hangupButton update];

	_optionsButton.enabled = (!call || !linphone_core_sound_resources_locked(LC));
	_optionsTransferButton.enabled = call && !linphone_core_sound_resources_locked(LC);
	// enable conference button if 2 calls are presents and at least one is not in the conference
	int confSize = linphone_core_get_conference_size(LC) - (linphone_core_is_in_conference(LC) ? 1 : 0);
	_optionsConferenceButton.enabled =
		((linphone_core_get_calls_nb(LC) > 1) && (linphone_core_get_calls_nb(LC) != confSize));

	// Disable transfert in conference
	if (linphone_core_get_current_call(LC) == NULL) {
		[_optionsTransferButton setEnabled:FALSE];
	} else {
		[_optionsTransferButton setEnabled:TRUE];
	}

	switch (state) {
		case LinphoneCallEnd:
		case LinphoneCallError:
		case LinphoneCallIncoming:
		case LinphoneCallOutgoing:
			[self hidePad:TRUE animated:TRUE];
			[self hideOptions:TRUE animated:TRUE];
			[self hideRoutes:TRUE animated:TRUE];
		default:
			break;
	}
}

- (void)toggleControls:(id)sender {
	bool controlsHidden = (_bottomBar.alpha == 0.0);
	[self hideControls:!controlsHidden sender:sender];
}

- (void)timerHideControls:(id)sender {
	[self hideControls:TRUE sender:sender];
}

- (void)hideControls:(BOOL)hidden sender:(id)sender {
	if (videoHidden && hidden)
		return;

	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[PhoneMainView.instance currentView] equal:CallView.compositeViewDescription]) {
		// show controls
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.35];
        
		_nameLabel.alpha = _durationLabel.alpha = (hidden ? 0 : .8f);

		[self hideStatusBar:hidden];

		[UIView commitAnimations];

		[PhoneMainView.instance hideTabBar:hidden];

		if (!hidden) {
			// hide controls in 5 sec
			hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
																 target:self
															   selector:@selector(timerHideControls:)
															   userInfo:nil
																repeats:NO];
		}
	}
}

- (void)disableVideoDisplay:(BOOL)disabled animated:(BOOL)animation {
	if (disabled == videoHidden && animation)
		return;
	videoHidden = disabled;

	if (!disabled) {
		[videoZoomHandler resetZoom];
	}
	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

    //  Leo Kelvin
    if (disabled) {
        _callView.hidden = NO;
        viewVideoCall.hidden = YES;
    }else{
        _callView.hidden = YES;
        viewVideoCall.hidden = NO;
    }

	[self hideControls:!disabled sender:nil];

	if (animation) {
		[UIView commitAnimations];
	}

	// only show camera switch button if we have more than 1 camera
	_videoPreview.hidden = (disabled || !linphone_core_self_view_enabled(LC));

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

    [[PhoneMainView instance] fullScreen: false];
    /*  Leo Kelvin
	[PhoneMainView.instance fullScreen:!disabled];
	[PhoneMainView.instance hideTabBar:!disabled];
    */

	if (!disabled) {
#ifdef TEST_VIDEO_VIEW_CHANGE
		[NSTimer scheduledTimerWithTimeInterval:5.0
										 target:self
									   selector:@selector(_debugChangeVideoView)
									   userInfo:nil
										repeats:YES];
#endif
		// [self batteryLevelChanged:nil];

		[_videoWaitingForFirstImage setHidden:NO];
		[_videoWaitingForFirstImage startAnimating];

		LinphoneCall *call = linphone_core_get_current_call(LC);
		// linphone_call_params_get_used_video_codec return 0 if no video stream enabled
		if (call != NULL && linphone_call_params_get_used_video_codec(linphone_call_get_current_params(call))) {
			linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, (__bridge void *)(self));
		}
	}
}

- (void)displayVideoCall:(BOOL)animated {
    float x = 0.5;
    float y = 0.5;
    linphone_call_zoom_video(linphone_core_get_current_call(LC), 1.32, &x, &y);
    
    [self addFooterViewForVideoCall];
    
	[self disableVideoDisplay:FALSE animated:animated];
}

- (void)displayAudioCall:(BOOL)animated {
	[self disableVideoDisplay:TRUE animated:animated];
}

- (void)hideStatusBar:(BOOL)hide {
	/* we cannot use [PhoneMainView.instance show]; because it will automatically
	 resize current view to fill empty space, which will resize video. This is
	 indesirable since we do not want to crop/rescale video view */
	PhoneMainView.instance.mainViewController.statusBarView.hidden = hide;
}

- (void)callDurationUpdate
{
    
    int size = linphone_core_get_conference_size(LC);
    NSLog(@"KL-----size: %d", size);
    
    int duration;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    if (list != NULL) {
        duration = linphone_call_get_duration((LinphoneCall*)list->data);
    }else{
        duration = 0;
    }
	_durationLabel.text = [LinphoneUtils durationToString:duration];
    _lbVideoTime.text = [LinphoneUtils durationToString:duration];

    if (duration > 0) {
        _lbState.text = [appDelegate.localization localizedStringForKey:text_connected];
        _lbState.textColor = [UIColor colorWithRed:(27/255.0) green:(175/255.0)
                                              blue:(153/255.0) alpha:1.0];
        
        [self callQualityUpdate];
        
    }else{
        _lbState.text = [appDelegate.localization localizedStringForKey:text_status_connecting];
        _lbState.textColor = UIColor.whiteColor;
    }
}

//  Call quality
- (void)callQualityUpdate {
    LinphoneCall *call;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    
    call = (LinphoneCall*)list->data;
    
    if(call != NULL) {
        //FIXME double check call state before computing, may cause core dump
        float quality = linphone_call_get_average_quality(call);
        if(quality < 1) {
            _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_worse]];
            
            NSRange range = [_lbQuality.text rangeOfString:[appDelegate.localization localizedStringForKey:text_quality_worse]];
            if (range.location != NSNotFound) {
                videoStateString = [[NSMutableAttributedString alloc] initWithString:_lbQuality.text];
                [videoStateString addAttribute:NSForegroundColorAttributeName
                               value:[UIColor redColor]
                               range:NSMakeRange(range.location, range.length)];
                lbStateVideoCall.attributedText = videoStateString;
            }
        } else if (quality < 2) {
            _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_very_low]];
            lbStateVideoCall.text = _lbQuality.text;
            
            NSRange range = [_lbQuality.text rangeOfString:[appDelegate.localization localizedStringForKey:text_quality_very_low]];
            if (range.location != NSNotFound) {
                videoStateString = [[NSMutableAttributedString alloc] initWithString:_lbQuality.text];
                [videoStateString addAttribute:NSForegroundColorAttributeName
                                         value:[UIColor orangeColor]
                                         range:NSMakeRange(range.location, range.length)];
                lbStateVideoCall.attributedText = videoStateString;
            }
        } else if (quality < 3) {
            _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_low]];
            
            NSRange range = [_lbQuality.text rangeOfString:[appDelegate.localization localizedStringForKey:text_quality_low]];
            if (range.location != NSNotFound) {
                videoStateString = [[NSMutableAttributedString alloc] initWithString:_lbQuality.text];
                [videoStateString addAttribute:NSForegroundColorAttributeName
                                         value:[UIColor orangeColor]
                                         range:NSMakeRange(range.location, range.length)];
                lbStateVideoCall.attributedText = videoStateString;
            }
        } else if(quality < 4){
            _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_average]];
            
            NSRange range = [_lbQuality.text rangeOfString:[appDelegate.localization localizedStringForKey:text_quality_average]];
            if (range.location != NSNotFound) {
                videoStateString = [[NSMutableAttributedString alloc] initWithString:_lbQuality.text];
                [videoStateString addAttribute:NSForegroundColorAttributeName
                                         value:[UIColor yellowColor]
                                         range:NSMakeRange(range.location, range.length)];
                lbStateVideoCall.attributedText = videoStateString;
            }
        } else{
            _lbQuality.text = [NSString stringWithFormat:@"%@: %@", [appDelegate.localization localizedStringForKey:text_quality], [appDelegate.localization localizedStringForKey:text_quality_good]];
            
            NSRange range = [_lbQuality.text rangeOfString:[appDelegate.localization localizedStringForKey:text_quality_good]];
            if (range.location != NSNotFound) {
                videoStateString = [[NSMutableAttributedString alloc] initWithString:_lbQuality.text];
                [videoStateString addAttribute:NSForegroundColorAttributeName
                                         value:[UIColor colorWithRed:(17/255.0) green:(186/255.0) blue:(153/255.0) alpha:1.0]
                                         range:NSMakeRange(range.location, range.length)];
                lbStateVideoCall.attributedText = videoStateString;
            }
        }
    }
}

- (void)onCurrentCallChange {
	LinphoneCall *call = linphone_core_get_current_call(LC);

	//  _callView.hidden = !call;
	//  _conferenceView.hidden = !linphone_core_is_in_conference(LC);
	//  _callPauseButton.hidden = !call && !linphone_core_is_in_conference(LC);

	//  [_callPauseButton setType:UIPauseButtonType_CurrentCall call:call];
	//  [_conferencePauseButton setType:UIPauseButtonType_Conference call:call];

    //  Leo Kelvin
    //  _callView.hidden = !call;
    
    BOOL check = !call && !linphone_core_is_in_conference(LC);
    if (check) {
        _callPauseButton.selected = YES;
    }else{
        _callPauseButton.selected = NO;
    }
    [_callPauseButton setType:UIPauseButtonType_CurrentCall call:call];
    /*
    _conferenceView.hidden = !linphone_core_is_in_conference(LC);
    [_conferencePauseButton setType:UIPauseButtonType_Conference call:call];    */
    
	if (!_callView.hidden) {
        /*  Leo Kelvin
		const LinphoneAddress *addr = linphone_call_get_remote_address(call);
		[ContactDisplay setDisplayNameLabel:_nameLabel forAddress:addr];
		char *uri = linphone_address_as_string_uri_only(addr);
		ms_free(uri);
		[_avatarImage setImage:[FastAddressBook imageForAddress:addr thumbnail:NO] bordered:YES withRoundedRadius:YES]; */
	}
}

- (void)hidePad:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[_numpadButton setOff];
	} else {
		[_numpadButton setOn];
	}
	if (hidden != _numpadView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_numpadView completion:nil];
		} else {
			[_numpadView setHidden:hidden];
		}
	}
}

- (void)hideRoutes:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[_routesButton setOff];
	} else {
		[_routesButton setOn];
	}

	_routesBluetoothButton.selected = LinphoneManager.instance.bluetoothEnabled;
    //  _routesSpeakerButton.selected = LinphoneManager.instance.speakerEnabled;
	_routesEarpieceButton.selected = !_routesBluetoothButton.selected && !_routesSpeakerButton.selected;

	if (hidden != _routesView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_routesView completion:nil];
		} else {
			[_routesView setHidden:hidden];
		}
	}
}

- (void)hideOptions:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[_optionsButton setOff];
	} else {
		[_optionsButton setOn];
	}
	if (hidden != _optionsView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_optionsView completion:nil];
		} else {
			[_optionsView setHidden:hidden];
		}
	}
}

- (void)hideSpeaker:(BOOL)hidden {
	_speakerButton.hidden = hidden;
	_routesButton.hidden = !hidden;
}

#pragma mark - Event Functions

- (void)bluetoothAvailabilityUpdateEvent:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool available = [[notif.userInfo objectForKey:@"available"] intValue];
        [self hideSpeaker:available];
    });
}

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state animated:TRUE];
}

- (NSString *)createDirectory {
    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"test.mp3"];
    NSLog(@"%@", path);
    return path;
}

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated
{
    // Add tất cả các cuộc gọi vào nhóm
    if (linphone_core_get_calls_nb(LC) >= 2) {
        NSLog(@"-----gop conference connected %d", linphone_core_get_calls_nb(LC));
        linphone_core_add_all_to_conference([LinphoneManager getLc]);
    }
    
	[self updateBottomBar:call state:state];
	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
    
    /*--Khong co goi conference--*/
    if(linphone_core_get_calls_nb([LinphoneManager getLc]) < 2 ){
        [self btnHideKeypadPressed];
        
        //  Neu dang goi video call thi thoi
        if (viewVideoCall == nil || viewVideoCall.hidden) {
            _callView.hidden = NO;
            _conferenceView.hidden = YES;
            viewVideoCall.hidden = YES;
        }else{
            NSLog(@"Dang bat video call");
        }
    }else{
        _callView.hidden = YES;
        _conferenceView.hidden = NO;
        viewVideoCall.hidden = YES;
    }

	static LinphoneCall *currentCall = NULL;
	if (!currentCall || linphone_core_get_current_call(LC) != currentCall) {
		currentCall = linphone_core_get_current_call(LC);
		[self onCurrentCallChange];
	}

	// Fake call update
	if (call == NULL) {
		return;
	}

	BOOL shouldDisableVideo =
		(!currentCall || !linphone_call_params_video_enabled(linphone_call_get_current_params(currentCall)));
	if (videoHidden != shouldDisableVideo) {
		if (!shouldDisableVideo) {
			[self displayVideoCall:animated];
		} else {
			[self displayAudioCall:animated];
		}
	}

	if (state != LinphoneCallPausedByRemote) {
		_pausedByRemoteView.hidden = YES;
	}

	switch (state) {
        case LinphoneCallIncomingReceived:{
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingInit:{
            typeCurrentCall = callOutgoing;
            
            // Nếu không phải Outgoing trong conference thì set disable các button
            if (!changeConference) {
                btnConference.enabled = NO;
                btnNumpad.enabled = NO;
                _videoButton.enabled = NO;
                _callPauseButton.enabled = NO;
                buttonRecord.enabled = NO;
                _microButton.enabled = NO;
                _optionsTransferButton.enabled = NO;
                buttonMessage.enabled = NO;
                buttonSendfile.enabled = NO;
            }
            break;
        }
        case LinphoneCallConnected:{
            
            LinphoneCall* currentCall = linphone_core_get_current_call(LC);
            
            LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(currentCall));
            //  ghi am
//            linphone_call_params_set_privacy(paramsCopy, 1);
            const char* lPlay = [[self createDirectory] cStringUsingEncoding:[NSString defaultCStringEncoding]];
            
            linphone_call_params_set_record_file(paramsCopy,lPlay);
            
            NSLog(@"File : %s",linphone_call_params_get_record_file(paramsCopy));
            linphone_call_start_recording(currentCall);
            
            btnConference.enabled = YES;
            btnNumpad.enabled = YES;
            _routesSpeakerButton.enabled = YES;
            _videoButton.enabled = YES;
            _callPauseButton.enabled = YES;
            _microButton.enabled = YES;
            _optionsTransferButton.enabled = YES;
            buttonMessage.enabled = YES;
            buttonRecord.enabled = YES;
            
            lbStateVideoCall.text = [NSString stringWithFormat:@"%@", [appDelegate.localization localizedStringForKey:text_connected]];
            
            // Add tất cả các cuộc gọi vào nhóm
            if (linphone_core_get_calls_nb(LC) >= 2) {
                linphone_core_add_all_to_conference([LinphoneManager getLc]);
            }
            
            break;
        }
		case LinphoneCallStreamsRunning: {
            // check video
			if (!linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
				const LinphoneCallParams *param = linphone_call_get_current_params(call);
				const LinphoneCallAppData *callAppData =
					(__bridge const LinphoneCallAppData *)(linphone_call_get_user_pointer(call));
				if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
					linphone_call_params_low_bandwidth_enabled(param)) {
				}
			}
            btnConference.enabled = YES;
            btnNumpad.enabled = YES;
            _routesSpeakerButton.enabled = YES;
            _videoButton.enabled = YES;
            _callPauseButton.enabled = YES;
            _microButton.enabled = YES;
            _optionsTransferButton.enabled = YES;
            buttonMessage.enabled = YES;
            buttonRecord.enabled = YES;
            
            // Add tất cả các cuộc gọi vào nhóm
            if (linphone_core_get_calls_nb(LC) >= 2) {
                linphone_core_add_all_to_conference([LinphoneManager getLc]);
            }
            
			break;
		}
		case LinphoneCallUpdatedByRemote: {
			const LinphoneCallParams *current = linphone_call_get_current_params(call);
			const LinphoneCallParams *remote = linphone_call_get_remote_params(call);

			/* remote wants to add video */
			if ((linphone_core_video_display_enabled(LC) && !linphone_call_params_video_enabled(current) &&
				 linphone_call_params_video_enabled(remote)) &&
				(!linphone_core_get_video_policy(LC)->automatically_accept ||
				 (([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) &&
				  floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max))) {
				linphone_core_defer_call_update(LC, call);
				[self displayAskToEnableVideoCall:call];
			} else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
				[self displayAudioCall:animated];
			}
			break;
		}
		case LinphoneCallPausing:
        case LinphoneCallPaused:{
            //  Close by Khai Le
            //  [self displayAudioCall:animated];
            break;
        }
		case LinphoneCallPausedByRemote:
			[self displayAudioCall:animated];
			if (call == linphone_core_get_current_call(LC)) {
				//  _pausedByRemoteView.hidden = NO;
			}
			break;
        case LinphoneCallEnd:{
            buttonRecord.selected = NO;
            
            if (durationTimer != nil) {
                [durationTimer invalidate];
                durationTimer = nil;
            }
            break;
        }
        case LinphoneCallError:{
            break;
        }
		default:
			break;
	}
}

#pragma mark - ActionSheet Functions

- (void)displayAskToEnableVideoCall:(LinphoneCall *)call {
	if (linphone_core_get_video_policy(LC)->automatically_accept &&
		!([UIApplication sharedApplication].applicationState == UIApplicationStateBackground))
		return;

	NSString *username = [FastAddressBook displayNameForAddress:linphone_call_get_remote_address(call)];
	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ would like to enable video", nil), username];
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground &&
		floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
		UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
		content.title = NSLocalizedString(@"Video request", nil);
		content.body = title;
		content.categoryIdentifier = @"video_request";
		content.userInfo = @{
			@"CallId" : [NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))]
		};

		UNNotificationRequest *req =
			[UNNotificationRequest requestWithIdentifier:@"video_request" content:content trigger:NULL];
		[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req
															   withCompletionHandler:^(NSError *_Nullable error) {
																 // Enable or disable features based on authorization.
																 if (error) {
																	 NSLog(@"Error while adding notification request :");
																	 NSLog(@"%@", error.description);
																 }
															   }];
	} else {
		UIConfirmationDialog *sheet = [UIConfirmationDialog ShowWithMessage:title
			cancelMessage:nil
			confirmMessage:NSLocalizedString(@"ACCEPT", nil)
			onCancelClick:^() {
			  NSLog(@"User declined video proposal");
			  if (call == linphone_core_get_current_call(LC)) {
				  LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
				  linphone_core_accept_call_update(LC, call, params);
				  linphone_call_params_destroy(params);
				  [videoDismissTimer invalidate];
				  videoDismissTimer = nil;
			  }
			}
			onConfirmationClick:^() {
			  NSLog(@"User accept video proposal");
			  if (call == linphone_core_get_current_call(LC)) {
				  LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
				  linphone_call_params_enable_video(params, TRUE);
				  linphone_core_accept_call_update(LC, call, params);
				  linphone_call_params_destroy(params);
				  [videoDismissTimer invalidate];
				  videoDismissTimer = nil;
			  }
			}
			inController:self];
		videoDismissTimer = [NSTimer scheduledTimerWithTimeInterval:30
															 target:self
														   selector:@selector(dismissVideoActionSheet:)
														   userInfo:sheet
															repeats:NO];
	}
}

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	UIConfirmationDialog *sheet = (UIConfirmationDialog *)timer.userInfo;
	[sheet dismiss];
}

#pragma mark VideoPreviewMoving

- (void)moveVideoPreview:(UIPanGestureRecognizer *)dragndrop {
	CGPoint center = [dragndrop locationInView:_videoPreview.superview];
	_videoPreview.center = center;
	if (dragndrop.state == UIGestureRecognizerStateEnded) {
		[self previewTouchLift];
	}
}

- (CGFloat)coerce:(CGFloat)value betweenMin:(CGFloat)min andMax:(CGFloat)max {
	return MAX(min, MIN(value, max));
}

- (void)previewTouchLift {
	CGRect previewFrame = _videoPreview.frame;
	previewFrame.origin.x = [self coerce:previewFrame.origin.x
							  betweenMin:5
								  andMax:(UIScreen.mainScreen.bounds.size.width - 5 - previewFrame.size.width)];
	previewFrame.origin.y = [self coerce:previewFrame.origin.y
							  betweenMin:5
								  andMax:(UIScreen.mainScreen.bounds.size.height - 5 - previewFrame.size.height)];

	if (!CGRectEqualToRect(previewFrame, _videoPreview.frame)) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		  [UIView animateWithDuration:0.3
						   animations:^{
                               NSLog(@"Recentering preview to %@", NSStringFromCGRect(previewFrame));
                               _videoPreview.frame = previewFrame;
						   }];
		});
	}
}

#pragma mark - Action Functions

- (IBAction)onNumpadClick:(id)sender {
    /*  Leo Kel vin
	if ([_numpadView isHidden]) {
		[self hidePad:FALSE animated:ANIMATED];
	} else {
		[self hidePad:TRUE animated:ANIMATED];
	}   */
    //  [_numpadButton setBackgroundColor:[UIColor clearColor]];
    // Install Popupview
    NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"UIMiniKeypad" owner:nil options:nil];
    UIMiniKeypad *viewKeypad;
    for(id currentObject in toplevelObject){
        if ([currentObject isKindOfClass:[UIMiniKeypad class]]) {
            viewKeypad = (UIMiniKeypad *) currentObject;
            break;
        }
    }
    
    float hKeyboard;
    if (SCREEN_WIDTH > 320) {
        hKeyboard = 280;
    }else{
        hKeyboard = 200;
    }
    
    float keypadY = _viewHeader.frame.origin.y+_viewHeader.frame.size.height + (SCREEN_HEIGHT-appDelegate._hStatus-_viewHeader.frame.size.height-hKeyboard)/2;
    
    viewKeypad.frame = CGRectMake((SCREEN_WIDTH-320)/2, keypadY, 320, hKeyboard);
    viewKeypad.tag = 10;
    [viewKeypad.zeroButton setDigit:'0'];
    [viewKeypad.zeroButton setDtmf:true] ;
    [viewKeypad.oneButton    setDigit:'1'];
    [viewKeypad.oneButton setDtmf:true];
    [viewKeypad.twoButton    setDigit:'2'];
    [viewKeypad.twoButton setDtmf:true];
    [viewKeypad.threeButton  setDigit:'3'];
    [viewKeypad.threeButton setDtmf:true];
    [viewKeypad.fourButton   setDigit:'4'];
    [viewKeypad.fourButton setDtmf:true];
    [viewKeypad.fiveButton   setDigit:'5'];
    [viewKeypad.fiveButton setDtmf:true];
    [viewKeypad.sixButton    setDigit:'6'];
    [viewKeypad.sixButton setDtmf:true];
    [viewKeypad.sevenButton  setDigit:'7'];
    [viewKeypad.sevenButton setDtmf:true];
    [viewKeypad.eightButton  setDigit:'8'];
    [viewKeypad.eightButton setDtmf:true];
    [viewKeypad.nineButton   setDigit:'9'];
    [viewKeypad.nineButton setDtmf:true];
    [viewKeypad.starButton   setDigit:'*'];
    [viewKeypad.starButton setDtmf:true];
    [viewKeypad.sharpButton  setDigit:'#'];
    [viewKeypad.sharpButton setDtmf:true];
    [viewKeypad setBackgroundColor:[UIColor clearColor]];
    
    [_viewCommand setHidden: true];
    [_callView addSubview:viewKeypad];
    [self fadeIn:viewKeypad];
    
    float wIcon = 60.0;
    float tmpMargin = (SCREEN_WIDTH - 2*wIcon)/3;
    float bottom;
    
    if (SCREEN_HEIGHT == 480) {
        bottom = 10.0;
    }else{
        bottom = 25.0;
    }
    
    btEndCall = [[UIHangUpButton alloc] initWithFrame:CGRectMake(tmpMargin, _callView.frame.size.height-wIcon-bottom, wIcon, wIcon)];
    [btEndCall setBackgroundImage:[UIImage imageNamed:@"decline_call_def.png"]
                         forState: UIControlStateNormal];
    [btEndCall setBackgroundImage:[UIImage imageNamed:@"decline_call_over.png"]
                         forState: UIControlStateHighlighted];
    [_callView addSubview: btEndCall];
    
    btHideKeypad = [[UIButton alloc] initWithFrame:CGRectMake(btEndCall.frame.origin.x+btEndCall.frame.size.width+tmpMargin, btEndCall.frame.origin.y, btEndCall.frame.size.width, btEndCall.frame.size.height)];
    [btHideKeypad setBackgroundImage:[UIImage imageNamed:@"close_keypad_def.png"]
                            forState:UIControlStateNormal ] ;
    [btHideKeypad setBackgroundImage:[UIImage imageNamed:@"close_keypad_act.png"]
                            forState: UIControlStateHighlighted];
    [btHideKeypad addTarget:self
                     action:@selector(btnHideKeypadPressed)
           forControlEvents:UIControlEventTouchUpInside];
    
    [_callView addSubview: btHideKeypad];
    
    [_hangupButton setHidden: true];
}

- (void)btnKeypadPressed {
    NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"UIMiniKeypad" owner:nil options:nil];
    UIMiniKeypad *viewKeypad;
    for(id currentObject in toplevelObject){
        if ([currentObject isKindOfClass:[UIMiniKeypad class]]) {
            viewKeypad = (UIMiniKeypad *) currentObject;
            break;
        }
    }
    
    float hKeyboard;
    if (SCREEN_WIDTH > 320) {
        hKeyboard = 280;
    }else{
        hKeyboard = 200;
    }
    
    float keypadY = _viewHeader.frame.origin.y+_viewHeader.frame.size.height + (SCREEN_HEIGHT-appDelegate._hStatus-_viewHeader.frame.size.height-hKeyboard)/2;
    
    viewKeypad.frame = CGRectMake((SCREEN_WIDTH-320)/2, keypadY, 320, hKeyboard);
    viewKeypad.tag = 10;
    [viewKeypad.zeroButton setDigit:'0'];
    [viewKeypad.zeroButton setDtmf:true] ;
    [viewKeypad.oneButton    setDigit:'1'];
    [viewKeypad.oneButton setDtmf:true];
    [viewKeypad.twoButton    setDigit:'2'];
    [viewKeypad.twoButton setDtmf:true];
    [viewKeypad.threeButton  setDigit:'3'];
    [viewKeypad.threeButton setDtmf:true];
    [viewKeypad.fourButton   setDigit:'4'];
    [viewKeypad.fourButton setDtmf:true];
    [viewKeypad.fiveButton   setDigit:'5'];
    [viewKeypad.fiveButton setDtmf:true];
    [viewKeypad.sixButton    setDigit:'6'];
    [viewKeypad.sixButton setDtmf:true];
    [viewKeypad.sevenButton  setDigit:'7'];
    [viewKeypad.sevenButton setDtmf:true];
    [viewKeypad.eightButton  setDigit:'8'];
    [viewKeypad.eightButton setDtmf:true];
    [viewKeypad.nineButton   setDigit:'9'];
    [viewKeypad.nineButton setDtmf:true];
    [viewKeypad.starButton   setDigit:'*'];
    [viewKeypad.starButton setDtmf:true];
    [viewKeypad.sharpButton  setDigit:'#'];
    [viewKeypad.sharpButton setDtmf:true];
    [viewKeypad setBackgroundColor:[UIColor clearColor]];
    
    [_viewCommand setHidden: true];
    [_callView addSubview:viewKeypad];
    [self fadeIn:viewKeypad];
    
    float wIcon = 60.0;
    float tmpMargin = (SCREEN_WIDTH - 2*wIcon)/3;
    float bottom;
    
    if (SCREEN_HEIGHT == 480) {
        bottom = 10.0;
    }else{
        bottom = 25.0;
    }
    
    btEndCall = [[UIHangUpButton alloc] initWithFrame:CGRectMake(tmpMargin, _callView.frame.size.height-wIcon-bottom, wIcon, wIcon)];
    [btEndCall setBackgroundImage:[UIImage imageNamed:@"decline_call_def.png"]
                         forState: UIControlStateNormal];
    [btEndCall setBackgroundImage:[UIImage imageNamed:@"decline_call_over.png"]
                         forState: UIControlStateHighlighted];
    [_callView addSubview: btEndCall];
    
    btHideKeypad = [[UIButton alloc] initWithFrame:CGRectMake(btEndCall.frame.origin.x+btEndCall.frame.size.width+tmpMargin, btEndCall.frame.origin.y, btEndCall.frame.size.width, btEndCall.frame.size.height)];
    [btHideKeypad setBackgroundImage:[UIImage imageNamed:@"close_keypad_def.png"]
                            forState:UIControlStateNormal ] ;
    [btHideKeypad setBackgroundImage:[UIImage imageNamed:@"close_keypad_act.png"]
                            forState: UIControlStateHighlighted];
    [btHideKeypad addTarget:self
                     action:@selector(btnHideKeypadPressed)
           forControlEvents:UIControlEventTouchUpInside];
    
    [_callView addSubview: btHideKeypad];
    
    _hangupButton.hidden = YES;
}

- (void)fadeIn :(UIView*)view{
    view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    view.alpha = 0.0;
    [UIView animateWithDuration:.35 animations:^{
        view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        view.alpha = 1.0;
    }];
}

- (IBAction)onChatClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
}

- (IBAction)onRoutesBluetoothClick:(id)sender {
	[self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:TRUE];
}

- (IBAction)onRoutesEarpieceClick:(id)sender {
	[self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:FALSE];
}

- (IBAction)onRoutesSpeakerClick:(id)sender {
    //  [self hideRoutes:TRUE animated:TRUE];
    if (![(UIButton *)sender isSelected]) {
        [LinphoneManager.instance setBluetoothEnabled:TRUE];
        [LinphoneManager.instance setSpeakerEnabled:FALSE];
    }else{
        [LinphoneManager.instance setBluetoothEnabled:FALSE];
        [LinphoneManager.instance setSpeakerEnabled:TRUE];
    }
}

- (IBAction)onRoutesClick:(id)sender {
	if ([_routesView isHidden]) {
		[self hideRoutes:FALSE animated:ANIMATED];
	} else {
		[self hideRoutes:TRUE animated:ANIMATED];
	}
}

- (IBAction)onOptionsClick:(id)sender {
	if ([_optionsView isHidden]) {
		[self hideOptions:FALSE animated:ANIMATED];
	} else {
		[self hideOptions:TRUE animated:ANIMATED];
	}
}

- (IBAction)onOptionsTransferClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = YES;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsAddClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = NO;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsConferenceClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	linphone_core_add_all_to_conference(LC);
}

#pragma mark - Animation

- (void)hideAnimation:(BOOL)hidden forView:(UIView *)target completion:(void (^)(BOOL finished))completion {
	if (hidden) {
	int original_y = target.frame.origin.y;
	CGRect newFrame = target.frame;
	newFrame.origin.y = self.view.frame.size.height;
	[UIView animateWithDuration:0.5
		delay:0.0
		options:UIViewAnimationOptionCurveEaseIn
		animations:^{
		  target.frame = newFrame;
		}
		completion:^(BOOL finished) {
		  CGRect originFrame = target.frame;
		  originFrame.origin.y = original_y;
		  target.hidden = YES;
		  target.frame = originFrame;
		  if (completion)
			  completion(finished);
		}];
	} else {
		CGRect frame = target.frame;
		int original_y = frame.origin.y;
		frame.origin.y = self.view.frame.size.height;
		target.frame = frame;
		frame.origin.y = original_y;
		target.hidden = NO;

		[UIView animateWithDuration:0.5
			delay:0.0
			options:UIViewAnimationOptionCurveEaseOut
			animations:^{
			  target.frame = frame;
			}
			completion:^(BOOL finished) {
			  target.frame = frame; // in case application did not finish
			  if (completion)
				  completion(finished);
			}];
	}
}

#pragma mark - Bounce

- (void)updateUnreadMessage:(BOOL)appear {
	int unreadMessage = [LinphoneManager unreadMessageCount];
	if (unreadMessage > 0) {
		_chatNotificationLabel.text = [NSString stringWithFormat:@"%i", unreadMessage];
		[_chatNotificationView startAnimating:appear];
	} else {
		[_chatNotificationView stopAnimating:appear];
	}
}

#pragma mark - My Functions

- (void)checkForNewMessageOfUser {
    NSString *sipPhone = [self getPhoneNumberOfCall];
    int unread = [NSDatabase getNumberMessageUnread:USERNAME andUser:sipPhone];
    if (unread > 0) {
        lbMsgCount.hidden = NO;
        lbMsgCount.text = [NSString stringWithFormat:@"%d", unread];
    }else{
        lbMsgCount.hidden = YES;
    }
}


//  Cập nhật table khi có message mới đến
- (void)messageReceived:(NSNotification*)notif
{
    id object = [notif userInfo];
    if ([object isKindOfClass:[NSMutableDictionary class]])
    {
        OTRMessage *message = [object objectForKey:@"message"];
        NSString *typeMessage = [object objectForKey:@"typeMessage"];
        
        NSString *user = @"";
        if (message != nil) {
            user = [AppUtils getSipFoneIDFromString: message.buddy.accountName];
        }else{
            user = [object objectForKey:@"user"];
        }
        
        NSString *sipPhone = [self getPhoneNumberOfCall];
        if (![user isEqualToString: sipPhone]) {
            [self createMessageNotifForUser:user forMessage:message.message withTypeMessage:typeMessage];
            return;
        }
        [self checkForNewMessageOfUser];
    }
}

- (void)createMessageNotifForUser: (NSString *)user forMessage: (NSString *)message withTypeMessage: (NSString *)typeMessage
{
    CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
    style.backgroundColor = [UIColor whiteColor];
    style.imageSize = CGSizeMake(35, 35);
    style.maxWidthPercentage = 0.9;
    style.horizontalPadding = 5;
    style.verticalPadding = 5;
    style.cornerRadius = 5.0;
    style.messageNumberOfLines = 1;
    style.titleNumberOfLines = 1;
    style.titleFont = [UIFont boldSystemFontOfSize:15.0];
    style.messageFont = [UIFont systemFontOfSize:13.0];
    
    //  Tạo notif thông báo message đến
    NSArray *infoArr = [NSDatabase getNameAndAvatarOfContactWithPhoneNumber: user];
    NSString *name = [infoArr firstObject];
    if ([name isEqualToString:@""]) {
        name = user;
    }
    
    NSString *avatar = [infoArr lastObject];
    UIImage *imgUser = [UIImage imageNamed:@"no_avatar"];
    if (![avatar isEqualToString:@""]) {
        imgUser = [UIImage imageWithData:[NSData dataFromBase64String: avatar]];
    }
    
    if ([typeMessage isEqualToString:imageMessage]) {
        message = [NSString stringWithFormat:@"%@ %@", name, [appDelegate.localization localizedStringForKey:sent_photo_to_you]];
    }else if ([typeMessage isEqualToString:videoMessage]){
        message = [NSString stringWithFormat:@"%@ %@", name, [appDelegate.localization localizedStringForKey:sent_video_to_you]];
    }else{
        NSAttributedString *content = [AppUtils convertMessageStringToEmojiString: message];
        message = content.string;
    }
    [self.view makeToast:message duration:1.5 position:CSToastPositionTop title:name image:imgUser style:style completion:^(BOOL didTap) {
        if (didTap) {
            appDelegate.reloadMessageList = YES;
            appDelegate.friendBuddy = [AppUtils getBuddyOfUserOnList: user];
            [[PhoneMainView instance] changeCurrentView:[MainChatViewController compositeViewDescription]
                                                   push:true];
        } else {
            NSLog(@"completion without tap");
        }
    }];
}




- (void)changeCamera {
    CABasicAnimation *animationView = [CABasicAnimation animationWithKeyPath:@"transform"];
    self.view.layer.zPosition = 100;
    CATransform3D transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    transform.m34 = 1.0/800.0;
    [animationView setToValue:[NSValue valueWithCATransform3D:transform]];
    [animationView setDuration:0.2];
    [animationView setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [animationView setFillMode:kCAFillModeBoth];
    [animationView setRemovedOnCompletion:YES];
    //[animationView setDelegate:self];
    [_videoPreview.layer addAnimation:animationView forKey:nil];
}

- (void)callEnded {
    buttonRecord.selected = NO;
}

//  Hide keypad mini
- (void)btnHideKeypadPressed{
    _viewCommand.hidden = NO;
    
    for (UIView *subView in _callView.subviews) {
        if (subView.tag == 10) {
            [UIView animateWithDuration:.35 animations:^{
                subView.transform = CGAffineTransformMakeScale(1.3, 1.3);
                subView.alpha = 0.0;
            } completion:^(BOOL finished) {
                if (finished) {
                    // [[NSNotificationCenter defaultCenter] removeObserver:self];
                    [subView removeFromSuperview];
                }
            }];
        }
    }
    //  An footer keypad
    btEndCall.hidden = YES;
    btHideKeypad.hidden = YES;
    _hangupButton.hidden = NO;
}

/*----- Kết thúc cuộc gọi trong màn hình video call -----*/
- (void)endVideoCall{
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentcall = linphone_core_get_current_call(lc);
    if (currentcall != nil) {
        linphone_core_terminate_call(lc, currentcall);
    }
}

- (void)whenTapOnVideoCall {
    if (videoCallFooterView.hidden) {
        lbAddressVideoCall.hidden = NO;
        icWaveVideo.hidden = NO;
        lbStateVideoCall.hidden = NO;
        icVideoCall.hidden = NO;
        _lbVideoTime.hidden = NO;
        videoCallFooterView.hidden = NO;
        
        iconCaptureScreen.hidden = YES;
    }else{
        lbAddressVideoCall.hidden = YES;
        icWaveVideo.hidden = YES;
        lbStateVideoCall.hidden = YES;
        icVideoCall.hidden = YES;
        _lbVideoTime.hidden = YES;
        videoCallFooterView.hidden = YES;
        
        iconCaptureScreen.hidden = NO;
    }
}

- (void)updateAddress {
    [self view]; //Force view load
    __block NSString *addressPhoneNumber = @"";
    __block NSString *avatar = @"";
    __block NSString *fullName = @"";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        LinphoneCore* lc = [LinphoneManager getLc];
        list = linphone_core_get_calls(lc);
        if (list != NULL) {
            LinphoneCall* call = list->data;
            const LinphoneAddress* addr = linphone_call_get_remote_address(call);
            if (addr != NULL) {
                // contact name
                char* lAddress = linphone_address_as_string_uri_only(addr);
                if(lAddress) {
                    NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
                    NSRange range = NSMakeRange(3, [normalizedSipAddress rangeOfString:@"@"].location - 3);
                    NSString *tmp = [normalizedSipAddress substringWithRange:range];
                    // tmp: -> :8889998007
                    if (tmp.length > 2) {
                        NSString *phoneStr = [tmp substringFromIndex: 1];
                        addressPhoneNumber = [[NSString alloc] initWithString: phoneStr];
                    }
                    ms_free(lAddress);
                }
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"_sipPhone == %@", addressPhoneNumber];
            NSArray *filter = [appDelegate.listContacts filteredArrayUsingPredicate: predicate];
            if (filter.count > 0) {
                ContactObject *aContact = [filter objectAtIndex: 0];
                avatar = aContact._avatar;
            }else{
                for (int iCount=0; iCount<appDelegate.listContacts.count; iCount++) {
                    ContactObject *contact = [appDelegate.listContacts objectAtIndex: iCount];
                    predicate = [NSPredicate predicateWithFormat:@"_valueStr = %@", addressPhoneNumber];
                    filter = [contact._listPhone filteredArrayUsingPredicate: predicate];
                    if (filter.count > 0) {
                        avatar = contact._avatar;
                        break;
                    }
                }
            }
            fullName = [NSDatabase getNameOfContactWithPhoneNumber: addressPhoneNumber];
            if ([fullName isEqualToString:@""]) {
                if ([addressPhoneNumber isEqualToString:hotline]) {
                    fullName = @"hotline";
                }else{
                    fullName = addressPhoneNumber;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _nameLabel.text = fullName;
            lbAddressVideoCall.text = fullName;
            lbAddressConf.text = fullName;
            lbAddressVideoCall.text = fullName;
            
            if ([addressPhoneNumber hasPrefix:@"778899"]) {
                buttonMessage.enabled = YES;
            }else{
                buttonMessage.enabled = NO;
            }
            if (![avatar isEqualToString:@""]) {
                _avatarImage.image = [UIImage imageWithData: [NSData dataFromBase64String: avatar]];
            }else{
                _avatarImage.image = [UIImage imageNamed:@"default-avatar"];
            }
        });
    });
}

//  add scroll view khi goi
- (void)addScrollview {
    //  Add scroll View
    _scrollView.frame = CGRectMake((_viewCommand.frame.size.width-3*wButton)/2, (_viewCommand.frame.size.height-2*wButton)/2, 3*wButton, 2*wButton);
    _scrollView.pagingEnabled = YES;
    _scrollView.accessibilityActivationPoint = CGPointMake(wButton, wButton);
    
    UIImageView *imgView;
    imgView = [[UIImageView alloc]initWithImage:
               [UIImage imageNamed:@"background_option_call.png"]];
    
    _scrollView.minimumZoomScale = 0.5;
    _scrollView.maximumZoomScale = 3;
    _scrollView.contentSize = CGSizeMake(5*wButton, 2*wButton);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    // Conference button
    btnConference = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, wButton, wButton) ];
    [btnConference setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_conference]]
                             forState:UIControlStateNormal];
    [btnConference setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_conference_over]]
                             forState: UIControlStateHighlighted];
    [btnConference setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_conference_dis]]
                             forState:UIControlStateDisabled];
    
    [btnConference addTarget:self
                      action:@selector(onConference)
            forControlEvents:UIControlEventTouchUpInside];
    btnConference.enabled = NO;
    [_scrollView addSubview:btnConference];
    
    // Keypad button
    _numpadButton.hidden = YES;
    btnNumpad = [[UIButton alloc] init];
    [btnNumpad setFrame: CGRectMake(wButton, 0, wButton, wButton)];
    [btnNumpad setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_keypad]]
                             forState:UIControlStateNormal] ;
    [btnNumpad setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_keypad_over]]
                             forState: UIControlStateHighlighted];
    [btnNumpad setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_keypad_over]]
                             forState: UIControlStateSelected];
    [btnNumpad setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_keypad_dis]]
                             forState:UIControlStateDisabled];
    [btnNumpad setBackgroundColor:[UIColor clearColor]];
    [btnNumpad setEnabled:false];
    [btnNumpad addTarget:self
                  action:@selector(btnKeypadPressed)
        forControlEvents:UIControlEventTouchUpInside];
    
    [_scrollView addSubview:btnNumpad];
    
    // Speaker button
    _routesSpeakerButton.frame = CGRectMake(2*wButton, 0, wButton, wButton);
    [_routesSpeakerButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_speaker]]
                              forState:UIControlStateNormal ] ;
    [_routesSpeakerButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_speaker_over]]
                              forState: UIControlStateHighlighted];
    [_routesSpeakerButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_speaker_over]]
                              forState: UIControlStateSelected];
    [_routesSpeakerButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_speaker_dis]]
                              forState:UIControlStateDisabled];
    [_routesSpeakerButton setEnabled: false];
    //  [self.scrollView addSubview:buttonSpeaker];
    
    // Video button
    _videoButton.frame = CGRectMake(0, wButton, wButton, wButton);
    [_videoButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_video]]
                            forState:UIControlStateNormal ] ;
    [_videoButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_video_over]]
                            forState: UIControlStateHighlighted];
    [_videoButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_video_over]]
                            forState: UIControlStateSelected];
    [_videoButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_video_dis]]
                            forState: UIControlStateDisabled];
    //  Tạm thời đóng
    _videoButton.enabled = NO;
    
    // Pause button
    _callPauseButton.frame = CGRectMake(wButton, wButton, wButton, wButton);
    [_callPauseButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_hold]]
                                forState:UIControlStateNormal] ;
    [_callPauseButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_hold_over]]
                                forState: UIControlStateHighlighted];
    [_callPauseButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_hold_over]]
                                forState: UIControlStateSelected];
    [_callPauseButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_hold_dis]]
                                forState: UIControlStateDisabled];
    [_callPauseButton setEnabled: false];
    //  [self.scrollView addSubview: pauseButton];
    
    // Record button
    buttonRecord = [[UIButton alloc] initWithFrame:CGRectMake(2*wButton, wButton, wButton, wButton) ];
    [buttonRecord setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_record]]
                            forState:UIControlStateNormal] ;
//    [buttonRecord setBackgroundImage:[UIImage imageNamed:[localization localizedStringForKey:img_record_over]]
//                            forState: UIControlStateHighlighted];
    [buttonRecord setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_record_over]]
                            forState: UIControlStateSelected];
    [buttonRecord setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_record_dis]]
                            forState:UIControlStateDisabled];
    [buttonRecord setEnabled:false];
    [buttonRecord setBackgroundColor: [UIColor clearColor]];
    
    [buttonRecord addTarget:self
                     action:@selector(btnRecordPressed:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [_scrollView addSubview:buttonRecord];
    
    // Mute button
    _microButton.frame = CGRectMake(3*wButton, 0, wButton, wButton);
    [_microButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_mute]]
                            forState:UIControlStateNormal ] ;
    [_microButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_mute_over]]
                            forState: UIControlStateHighlighted];
    [_microButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_mute_over]]
                            forState: UIControlStateSelected];
    [_microButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_mute_dis]]
                            forState:UIControlStateDisabled];
    [_microButton setEnabled: false];
    //  [self.scrollView addSubview:buttonMute];
    
    // Transfer button
    _optionsTransferButton.frame = CGRectMake(4*wButton, 0, wButton, wButton);
    [_optionsTransferButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_transfer]]
                                      forState:UIControlStateNormal ] ;
    [_optionsTransferButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_transfer_over]]
                                      forState: UIControlStateHighlighted];
    [_optionsTransferButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_transfer_over]]
                                      forState: UIControlStateSelected];
    [_optionsTransferButton setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_transfer_dis]]
                                      forState:UIControlStateDisabled];
    _optionsTransferButton.enabled = NO;
    
    /*  Leo Kelvin
     [buttonTransfer addTarget:self action:@selector(onTransfer)
     forControlEvents:UIControlEventTouchUpInside];
     */
    //  [self.scrollView addSubview:buttonTransfer];
    
    // Message button
    buttonMessage = [[UIButton alloc] initWithFrame:CGRectMake(3*wButton, wButton, wButton, wButton)  ];
    [buttonMessage setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_message]]
                             forState:UIControlStateNormal ] ;
    [buttonMessage setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_message_over]]
                             forState: UIControlStateHighlighted];
    [buttonMessage setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_message_over]]
                             forState: UIControlStateSelected];
    [buttonMessage setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_message_dis]]
                             forState:UIControlStateDisabled];
    
    [buttonMessage addTarget:self
                      action:@selector(goToViewChatInCallView)
            forControlEvents:UIControlEventTouchUpInside];
    [buttonMessage setEnabled:false];
    [_scrollView addSubview:buttonMessage];
    
    lbMsgCount = [[UILabel alloc] initWithFrame: CGRectMake(buttonMessage.center.x+wButton/8, buttonMessage.frame.origin.y, wButton/4, wButton/4)];
    lbMsgCount.backgroundColor = [UIColor redColor];
    lbMsgCount.font = textFont;
    lbMsgCount.textColor = [UIColor whiteColor];
    lbMsgCount.textAlignment = NSTextAlignmentCenter;
    lbMsgCount.layer.cornerRadius = wButton/8;
    lbMsgCount.clipsToBounds = YES;
    [self checkForNewMessageOfUser];
    
    [_scrollView addSubview: lbMsgCount];
    
    // Send file button
    buttonSendfile = [[UIButton alloc] initWithFrame:CGRectMake(4*wButton, wButton, wButton, wButton)];
    [buttonSendfile setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_send]]
                              forState:UIControlStateNormal ] ;
    [buttonSendfile setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_send_over]]
                              forState: UIControlStateHighlighted];
    [buttonSendfile setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_send_over]]
                              forState: UIControlStateSelected];
    [buttonSendfile setBackgroundImage:[UIImage imageNamed:[appDelegate.localization localizedStringForKey:img_send_dis]]
                              forState:UIControlStateDisabled];
    buttonSendfile.enabled = NO;
    [_scrollView addSubview:buttonSendfile];
}

/*----- Click vao button conference trong scrollView  -----*/
-(void)onConference {
    changeConference = YES;
    _lbConferenceDuration.text = [appDelegate.localization localizedStringForKey:text_connected];
    btnConference.backgroundColor = UIColor.clearColor;
    _callView.hidden = YES;
    _conferenceView.hidden = NO;
    
    NSDictionary *info = [NSDatabase getProfileInfoOfAccount: USERNAME];
    if (info != nil) {
        NSString *strAvatar = [info objectForKey:@"avatar"];
        if (strAvatar != nil && ![strAvatar isEqualToString: @""]) {
            NSData *myAvatar = [NSData dataFromBase64String: strAvatar];
            avatarConference.image = [UIImage imageWithData: myAvatar];
        }else{
            avatarConference.image = [UIImage imageNamed:@"no_avatar"];
        }
    }else{
        avatarConference.image = [UIImage imageNamed:@"no_avatar"];
    }
    lbAddressConf.text = USERNAME;
    
    updateTimeConf = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateConference) userInfo:nil repeats:YES];
}

- (void)updateConference {
    LinphoneCore *lc = [LinphoneManager getLc];
    [collectionConference reloadData];
    
    int count = 0;
    list = linphone_core_get_calls(lc);
    while (list != NULL) {
        count++;
        list = list->next;
    }
    
    if (count > 2) {
        changeConference = NO;
    }
    
    if (count == 1 && changeConference == NO) {
        [self hiddenConference];
        //Update address
        [self updateAddress];
        
        [updateTimeConf invalidate];
        updateTimeConf = nil;
        //  updateTime = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCall) userInfo:nil repeats:YES];
    }
    
    if (count < 1) {
        [updateTimeConf invalidate];
        updateTimeConf = nil;
    }
}

//  Ẩn confernce
- (void)hiddenConference{
    [_callView setHidden: NO];
    [_conferenceView setHidden: YES];
}

- (void)btnRecordPressed: (UIButton *)sender
{
    if (sender.tag == 0) {
        [sender setTag: 1];
        [sender setSelected: true];
        
        //  Bật cờ ghi âm
        if (appDelegate == nil) {
            appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
        }
        [appDelegate set_hasRecordCall: true];
        
        NSLog(@"On Record");
        LinphoneCore *lc = [LinphoneManager getLc];
        LinphoneCall *currentCall = linphone_core_get_current_call(lc);
        linphone_call_start_recording(currentCall);
    }else{
        [sender setTag: 0];
        [sender setSelected: false];
        
        LinphoneCore* lc = [LinphoneManager getLc];
        LinphoneCall* currentCall = linphone_core_get_current_call(lc);
        linphone_call_stop_recording(currentCall);
    }
}

- (void)setupUIForView {
    
    if (SCREEN_WIDTH > 320) {
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    }else{
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:16.0];
    }
    
    //  View call binh thuong
    [_viewHeader setFrame: CGRectMake(0, 0, SCREEN_WIDTH, 35.0)];
    
    [_icLogo setFrame: CGRectMake(10, (_viewHeader.frame.size.height-22)/2, 22.0, 22.0)];
    [_lbQuality setFrame: CGRectMake(_viewHeader.frame.size.width-_icLogo.frame.origin.x-200, 0, 200, _viewHeader.frame.size.height)];
    [_lbQuality setFont:[UIFont fontWithName:HelveticaNeue size:14.0]];
    [_lbQuality setTextColor: [UIColor whiteColor]];
    
    [_callView setFrame: CGRectMake(0, _viewHeader.frame.origin.y+_viewHeader.frame.size.height, SCREEN_WIDTH, SCREEN_HEIGHT-(_viewHeader.frame.size.height+appDelegate._hStatus))];
    
    //  float hHeader = SCREEN_WIDTH*445/1280;
    
    float hInfo;
    if (SCREEN_WIDTH > 320) {
        hIconEndCall = 60.0;
        hInfo = 120.0;
        wButton = 100.0;
        [_lbState setFont:[UIFont fontWithName:HelveticaNeue size:17.0]];
        
        [_hangupButton setFrame: CGRectMake((SCREEN_WIDTH-60)/2, _callView.frame.size.height-hIconEndCall-35, hIconEndCall, hIconEndCall)];
    }else{
        hIconEndCall = 60.0;
        hInfo = 90.0;
        wButton = 90.0;
        [_lbState setFont:[UIFont fontWithName:HelveticaNeue size:15.0]];
        
        [_hangupButton setFrame: CGRectMake((SCREEN_WIDTH-60)/2, _callView.frame.size.height-hIconEndCall-25, hIconEndCall, hIconEndCall)];
    }
    
    [_hangupButton addTarget:self
                      action:@selector(btnHangupButtonPressed)
            forControlEvents:UIControlEventTouchUpInside];
    
    [_viewInfo setFrame: CGRectMake(0, 0, SCREEN_WIDTH, hInfo)];
    [_bgHeader setFrame: CGRectMake(0, 0, _viewInfo.frame.size.width, _viewInfo.frame.size.height)];
    
    [_avatarImage setFrame: CGRectMake(10, 10, hInfo-20, hInfo-20)];
    [_avatarImage.layer setCornerRadius: 0];
    
    [_nameLabel setFrame: CGRectMake(_avatarImage.frame.origin.x+_avatarImage.frame.size.width+10, _avatarImage.frame.origin.y, SCREEN_WIDTH-(_avatarImage.frame.origin.x+_avatarImage.frame.size.width+10+60), _avatarImage.frame.size.height/2)];
    [_nameLabel setFont: textFont];
    [_nameLabel setTextColor:[UIColor whiteColor]];
    [_nameLabel setBackgroundColor:[UIColor clearColor]];
    
    [_lbState setFrame: CGRectMake(_nameLabel.frame.origin.x, _nameLabel.frame.origin.y+_nameLabel.frame.size.height, _viewInfo.frame.size.width-(2*_avatarImage.frame.origin.x+_avatarImage.frame.size.width+5), _nameLabel.frame.size.height)];
    [_lbState setTextColor:[UIColor whiteColor]];
    
    [_durationLabel setFrame: CGRectMake(0, _viewInfo.frame.origin.y+_viewInfo.frame.size.height+5, SCREEN_WIDTH, 50)];
    [_durationLabel setFont:[UIFont fontWithName:HelveticaNeue size:40.0]];
    [_durationLabel setBackgroundColor:[UIColor clearColor]];
    
    [_hangupButton setBackgroundImage:[UIImage imageNamed:@"decline_call_over.png"]
                             forState:UIControlStateHighlighted];
    
    [_viewCommand setFrame: CGRectMake(0, _durationLabel.frame.origin.y+_durationLabel.frame.size.height, SCREEN_WIDTH, _hangupButton.frame.origin.y-25-(_durationLabel.frame.origin.y+_durationLabel.frame.size.height+25))];
    [_viewCommand setBackgroundColor:[UIColor clearColor]];
    
    //  conference
    [_conferenceView setFrame: CGRectMake(0, _viewHeader.frame.origin.y+_viewHeader.frame.size.height, SCREEN_WIDTH, _callView.frame.size.height)];
    
    marginX = 5.0;
    wCollection = (SCREEN_WIDTH - 6*marginX)/2;
    [detailConference setFrame: CGRectMake(0, 0, SCREEN_WIDTH, hInfo)];
    
    [_bgHeaderConf setFrame: CGRectMake(0, 0, detailConference.frame.size.width, detailConference.frame.size.height)];
    [avatarConference setFrame: CGRectMake(5, 5, hInfo-10, hInfo-10)];
    [lbAddressConf setFrame: CGRectMake(avatarConference.frame.origin.x+avatarConference.frame.size.width+10, avatarConference.frame.origin.y, SCREEN_WIDTH-(2*avatarConference.frame.origin.x+avatarConference.frame.size.width+10), avatarConference.frame.size.height/3)];
    [lbAddressConf setFont: textFont];
    
    [_lbConferenceDuration setFrame: CGRectMake(lbAddressConf.frame.origin.x, lbAddressConf.frame.origin.y+lbAddressConf.frame.size.height, lbAddressConf.frame.size.width, lbAddressConf.frame.size.height)];
    [_lbConferenceDuration setFont: textFont];
    
    [btnAddCallConf setFrame: CGRectMake(_lbConferenceDuration.frame.origin.x, _lbConferenceDuration.frame.origin.y+_lbConferenceDuration.frame.size.height, (_lbConferenceDuration.frame.size.width-20)/2, _lbConferenceDuration.frame.size.height)];
    [btnEndCallConf setFrame: CGRectMake(btnAddCallConf.frame.origin.x+btnAddCallConf.frame.size.width+20, btnAddCallConf.frame.origin.y, btnAddCallConf.frame.size.width, btnAddCallConf.frame.size.height)];
    
    [collectionConference setFrame: CGRectMake(marginX, detailConference.frame.origin.y+detailConference.frame.size.height, SCREEN_WIDTH-2*marginX, SCREEN_HEIGHT-(detailConference.frame.origin.y+detailConference.frame.size.height+appDelegate._hStatus))];
    
    //  Setup for conference collection
    [collectionConference registerNib:[UINib nibWithNibName:@"UIConferenceCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"UIConferenceCell"];
    [collectionConference setDelegate: self];
    [collectionConference setDataSource: self];
    [collectionConference setBackgroundColor:[UIColor clearColor]];
    
    [btnAddCallConf.titleLabel setFont: textFont];
    [btnAddCallConf setTitle:[appDelegate.localization localizedStringForKey:CN_TEXT_ADD_CONFERENCE]
                    forState:UIControlStateNormal];
    [btnAddCallConf setBackgroundImage:[UIImage imageNamed:@"btn_add_conf_over.png"]
                              forState:UIControlStateHighlighted];
    [btnAddCallConf setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
    [btnAddCallConf addTarget:self
                       action:@selector(onAddCallForConference)
             forControlEvents:UIControlEventTouchUpInside];
    
    [btnEndCallConf.titleLabel setFont: textFont];
    [btnEndCallConf setTitle: [appDelegate.localization localizedStringForKey:CN_TEXT_END_CONFERENCE]
                    forState:UIControlStateNormal];
    [btnEndCallConf setBackgroundImage:[UIImage imageNamed:@"btn_end_conf_over.png"]
                              forState:UIControlStateHighlighted];
    [btnEndCallConf setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
    [btnEndCallConf addTarget:self
                       action:@selector(endConferenceCall)
             forControlEvents:UIControlEventTouchUpInside];
    
    //  video call
    [viewVideoCall setFrame: CGRectMake(0, 0, SCREEN_WIDTH, _callView.frame.size.height+_viewHeader.frame.size.height)];
    
    if (SCREEN_WIDTH > 320) {
        [_lbVideoTime setFont: [UIFont fontWithName:MYRIADPRO_REGULAR size:15.0]];
    }else{
        [_lbVideoTime setFont:[UIFont fontWithName:MYRIADPRO_REGULAR size:15.0]];
    }
    [_lbVideoTime setTextColor:[UIColor whiteColor]];
    [_lbVideoTime setBackgroundColor:[UIColor clearColor]];
    [_lbVideoTime setTextAlignment: NSTextAlignmentLeft];
    
    float wPreviewVideo;
    if (SCREEN_WIDTH > 320) {
        wPreviewVideo = 100.0;
    }else{
        wPreviewVideo = 80.0;
    }
    
    //  _videoPreview.clipsToBounds = true;
    [_videoPreview setFrame: CGRectMake(SCREEN_WIDTH-20-100, 20, 100, 135)];
    _videoPreview.layer.cornerRadius = 10;
    _videoPreview.layer.borderColor = [UIColor whiteColor].CGColor;
    _videoPreview.layer.borderWidth = 1.0;
    _videoPreview.clipsToBounds = YES;
    
    _videoView.frame = CGRectMake(0, 0, viewVideoCall.frame.size.width, viewVideoCall.frame.size.height);
    
    iconCaptureScreen.frame = CGRectMake((viewVideoCall.frame.size.width-50)/2, viewVideoCall.frame.size.height-50-15, 50.0, 50.0);
}

- (void)onAddCallForConference
{
    [appDelegate set_acceptCall: true];
    
    //  [self hideOptions:TRUE animated:TRUE];
    DialerView *view = VIEW(DialerView);
    [view setAddress:@""];
    LinphoneManager.instance.nextCallIsTransfer = NO;
    [PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

//  Kết thúc gọi conference
- (void)endConferenceCall{
    linphone_core_terminate_all_calls([LinphoneManager getLc]);
}

//  Kết thúc cuộc gọi hiện tại
- (void)btnHangupButtonPressed {
    // Bien cho biết mình kết thúc cuộc gọi
    appDelegate._meEnded = YES;
}

- (void)goToViewChatInCallView {
    NSString *sipPhone = [self getPhoneNumberOfCall];
    
    appDelegate.reloadMessageList = YES;
    appDelegate.friendBuddy = [AppUtils getBuddyOfUserOnList: sipPhone];
    [[PhoneMainView instance] changeCurrentView:[MainChatViewController compositeViewDescription]
                                           push:true];
}

#pragma mark - Call Conference
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"UIConferenceCell";
    UIConferenceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setFrame: CGRectMake(cell.frame.origin.x, cell.frame.origin.y, wCollection, wCollection+60)];
    [cell setupUIForCell];
    
    LinphoneCore *lc = [LinphoneManager getLc];
    list = linphone_core_get_calls(lc);
    int i = 0;
    while (i < indexPath.row) {
        i++;
        list = list->next;
    }
    
    cell.call =(LinphoneCall*)list->data;
    int duration = linphone_call_get_duration((LinphoneCall*)list->data);
    [cell setDuration: duration];
    
    //set tag for ui
    [cell._btnPause setTag: indexPath.row];
    [cell._btnEndCall setTag: indexPath.row];
    
    int callState = linphone_call_get_state((LinphoneCall *)list->data);
    
    if (callState == LinphoneCallPaused) {
        [cell._btnPause setBackgroundImage:[UIImage imageNamed:@"button-stop-default.png"]
                                  forState:UIControlStateNormal];
        [cell._btnPause setBackgroundImage:[UIImage imageNamed:@"button-stop-active.png"]
                                  forState:UIControlStateHighlighted];
    }else{
        [cell._btnPause setBackgroundImage:[UIImage imageNamed:@"button-play-default.png"]
                                  forState:UIControlStateNormal];
        [cell._btnPause setBackgroundImage:[UIImage imageNamed:@"button-play-active.png"]
                                  forState:UIControlStateHighlighted];
    }
    [cell._btnPause addTarget:self action:@selector(onClickPause:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [cell._btnEndCall addTarget:self action:@selector(onClickEndCallConf:)
               forControlEvents:UIControlEventTouchUpInside];
    
    [cell updateCell];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(wCollection, wCollection+60);
}

#pragma mark collection view cell paddings
- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(marginX, marginX, marginX, marginX); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return marginX;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return marginX;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == _videoPreview)
    {
        return FALSE;
    }
    else
    {

        // here is remove keyBoard code
        return TRUE;
    }
}

- (void)turnOnOrTurnOffCamera
{
    /*  Leo Kelvin
    LinphoneCall *call = linphone_core_get_current_call(LC);
    BOOL enabled = linphone_call_camera_enabled(call);
    if (enabled) {
        if (call != NULL)
        {
            //  LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
            LinphoneCallParams* call_params = linphone_call_params_copy(linphone_call_get_current_params(call));
            linphone_call_enable_camera(call, FALSE);
            linphone_core_update_call(LC, call, call_params);
            //linphone_call_accept_update(call, call_params);
            
            [videoCallFooterView.footerCameraOff setBackgroundImage:[UIImage imageNamed:@"call_camera_off_selected"]
                                      forState:UIControlStateNormal];
            icOffCameraForPreview.hidden = NO;
        }
    }else{
        if (call != NULL) {
            linphone_call_enable_camera(call, TRUE);
            //linphone_core_update_call(LC, call, NULL);
            [videoCallFooterView.footerCameraOff setBackgroundImage:[UIImage imageNamed:@"call_camera_off"]
                                      forState:UIControlStateNormal];
            icOffCameraForPreview.hidden = YES;
        }
    }   */
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    
    if (!linphone_core_video_display_enabled(LC))
        return;
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call) {
        //  LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
        LinphoneCallParams* call_params = linphone_call_params_copy(linphone_call_get_current_params(call));
        linphone_call_params_enable_video(call_params, FALSE);
        linphone_core_update_call(LC, call, call_params);
        linphone_call_params_destroy(call_params);
    } else {
        NSLog(@"Cannot toggle video button, because no current call");
    }
    [self displayAudioCall: true];
}

- (void)addFooterViewForVideoCall
{
    float hFooterView = 10 + hIconEndCall + 10;
    if (videoCallFooterView == nil) {
        NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"FooterVideoCallView" owner:nil options:nil];
        for(id currentObject in toplevelObject){
            if ([currentObject isKindOfClass:[FooterVideoCallView class]]) {
                videoCallFooterView = (FooterVideoCallView *) currentObject;
                break;
            }
        }
        videoCallFooterView.frame = CGRectMake(0, viewVideoCall.frame.size.height-hFooterView, viewVideoCall.frame.size.width, hFooterView);
        [videoCallFooterView setupUIForView];
        
        [videoCallFooterView.footerCameraOff addTarget:self
                                                action:@selector(turnOnOrTurnOffCamera)
                                      forControlEvents:UIControlEventTouchUpInside];
        [videoCallFooterView.footerEndCall addTarget:self
                                              action:@selector(endVideoCall)
                                    forControlEvents:UIControlEventTouchUpInside];
        
        [viewVideoCall addSubview: videoCallFooterView];
    }
    videoCallFooterView.hidden = YES;
    iconCaptureScreen.hidden = NO;
    
    //  Address video
    lbAddressVideoCall.frame = CGRectMake(10, _videoPreview.frame.origin.y, 150, 30);
    lbAddressVideoCall.textColor = [UIColor whiteColor];
    lbAddressVideoCall.hidden = YES;
    
    if (icVideoCall == nil) {
        icVideoCall = [[UIImageView alloc] initWithFrame: CGRectMake(lbAddressVideoCall.frame.origin.x, lbAddressVideoCall.frame.origin.y+lbAddressVideoCall.frame.size.height+(lbAddressVideoCall.frame.size.height-18)/2, 18, 18)];
        icVideoCall.image = [UIImage imageNamed:@"white_video_call"];
        [viewVideoCall addSubview: icVideoCall];
    }
    icVideoCall.hidden = YES;
    
    _lbVideoTime.frame = CGRectMake(icVideoCall.frame.origin.x+icVideoCall.frame.size.width+5, lbAddressVideoCall.frame.origin.y+lbAddressVideoCall.frame.size.height, lbAddressVideoCall.frame.size.width, lbAddressVideoCall.frame.size.height);
    _lbVideoTime.hidden = YES;
    
    if (icWaveVideo == nil) {
        icWaveVideo = [[UIImageView alloc] initWithFrame: CGRectMake(icVideoCall.frame.origin.x, _lbVideoTime.frame.origin.y+_lbVideoTime.frame.size.height+(_lbVideoTime.frame.size.height-18)/2, 18.0, 18.0)];
        icWaveVideo.image = [UIImage imageNamed:@"white_wave_call"];
        [viewVideoCall addSubview: icWaveVideo];
    }
    icWaveVideo.hidden = YES;
    
    lbStateVideoCall.frame = CGRectMake(_lbVideoTime.frame.origin.x, _lbVideoTime.frame.origin.y+_lbVideoTime.frame.size.height, _lbVideoTime.frame.size.width, _lbVideoTime.frame.size.height);
    lbStateVideoCall.hidden = YES;
    
    if (icOffCameraForPreview == nil) {
        icOffCameraForPreview = [[UIImageView alloc] initWithFrame: CGRectMake((_videoPreview.frame.size.width-60)/2, (_videoPreview.frame.size.height-60)/2, 60, 60)];
        icOffCameraForPreview.image = [UIImage imageNamed:@"call_camera_off"];
        [_videoPreview addSubview: icOffCameraForPreview];
    }
    icOffCameraForPreview.hidden = YES;
}

- (NSString *)getPhoneNumberOfCall {
    __block NSString *addressPhoneNumber = @"";
    LinphoneCore* lc = [LinphoneManager getLc];
    list = linphone_core_get_calls(lc);
    if (list != NULL) {
        LinphoneCall* call = list->data;
        const LinphoneAddress* addr = linphone_call_get_remote_address(call);
        if (addr != NULL) {
            // contact name
            char* lAddress = linphone_address_as_string_uri_only(addr);
            if(lAddress) {
                NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
                NSRange range = NSMakeRange(3, [normalizedSipAddress rangeOfString:@"@"].location - 3);
                NSString *tmp = [normalizedSipAddress substringWithRange:range];
                // tmp: -> :8889998007
                if (tmp.length > 2) {
                    NSString *phoneStr = [tmp substringFromIndex: 1];
                    addressPhoneNumber = [[NSString alloc] initWithString: phoneStr];
                    return addressPhoneNumber;
                }
                ms_free(lAddress);
            }
        }
    }
    return @"";
}

- (IBAction)iconCaptureScreenClicked:(UIButton *)sender {
    UIImage *screengrab = [self takeAScreenShot];
    if (screengrab != nil) {
        [self.view makeToast:@"Sending......"];
        [self sendCaptureImageToUser: screengrab];
    }else{
        [self.view makeToast:[appDelegate.localization localizedStringForKey:text_cannot_send_picture] duration:2.0 position:CSToastPositionCenter];
    }
}

-(UIImage *)takeAScreenShot {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize size = CGSizeMake(_videoView.bounds.size.width*scale, _videoView.bounds.size.height*scale);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    [_videoView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (!error) {
        [self.view makeToast:[appDelegate.localization localizedStringForKey:text_save_image_success]
               duration:2.0 position:CSToastPositionCenter];
    } else {
        [self.view makeToast:[appDelegate.localization localizedStringForKey:text_save_image_failed]
               duration:2.0 position:CSToastPositionCenter];
    }
}

/*----- Pasuse and resume call -----*/
- (void)onClickPause:(UIButton *)sender {
    NSIndexPath *curIndex = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    UIConferenceCell *curCell = (UIConferenceCell *)[collectionConference cellForItemAtIndexPath: curIndex];
    LinphoneCallState state = linphone_call_get_state(curCell.call);
    if (state == LinphoneCallStreamsRunning){
        linphone_core_pause_call([LinphoneManager getLc], curCell.call);
    }else if (state == LinphoneCallPaused){
        linphone_core_resume_call([LinphoneManager getLc], curCell.call);
    }
}

/*----- End call conference trong từng cell -----*/
- (void)onClickEndCallConf:(UIControl *)sender {
    NSIndexPath *curIndex = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    UIConferenceCell *curCell = (UIConferenceCell *)[collectionConference cellForItemAtIndexPath: curIndex];
    linphone_core_terminate_call([LinphoneManager getLc], curCell.call);
    changeConference = NO;
}

//  Add new by Khai Le on 07/07/2018
- (void)startUploadImage: (UIImage *)uploadImage toServerWithMessageId: (NSString *)idMessage andName: (NSString *)imageName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = UIImageJPEGRepresentation(uploadImage, 1.0);
        UploadPicture *session = [[UploadPicture alloc] init];
        session.idMessage = idMessage;
        
        [session uploadData:imageData withName:imageName beginUploadBlock:nil finishUploadBlock:^(UploadPicture *uploadSession) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([uploadSession.namePicture isEqualToString:@"error"])
                {
                    [self.view makeToast:[appDelegate.localization localizedStringForKey:text_cannot_send_picture] duration:2.0 position:CSToastPositionCenter];
                }else{
                    NSString *displayName = [NSDatabase getProfielNameOfAccount: USERNAME];
                    NSString *remoteParty = [self getPhoneNumberOfCall];
                    
                    NSString *strPush = [appDelegate.localization localizedStringForKey:sent_message_to_you];
                    strPush = [NSString stringWithFormat:@"%@ %@", displayName, [appDelegate.localization localizedStringForKey:sent_photo_to_you]];
                    
                    [AppUtils sendMessageForOfflineForUser:remoteParty fromSender:USERNAME withContent:strPush andTypeMessage:userimage withGroupID:@""];
                    
                    int burn = [AppUtils getBurnMessageValueOfRemoteParty: remoteParty];
                    [appDelegate.myBuddy.protocol sendMessageMediaForUser:remoteParty withLinkImage:uploadSession.namePicture andDescription:appDelegate.titleCaption andIdMessage:idMessage andType:userimage withBurn:burn forGroup:NO];
                    
                    [self.view makeToast:[appDelegate.localization localizedStringForKey:text_capture_sent] duration:2.0 position:CSToastPositionCenter];
                }
            });
        }];
    });
}

- (void)sendCaptureImageToUser: (UIImage *)captureImage
{
    NSString *remoteParty = [self getPhoneNumberOfCall];
    NSString *idMsgImage = [NSString stringWithFormat:@"userimage_%@", [AppUtils randomStringWithLength: 20]];
    NSString *detailURL = [NSString stringWithFormat:@"%@_%@.jpg", USERNAME, [AppUtils randomStringWithLength:20]];
    
    int delivered = 0;
    if (appDelegate.xmppStream.isConnected) {
        delivered = 1;
    }
    
    NSArray *fileNameArr = [AppUtils saveImageToFiles: captureImage withImage: detailURL];
    detailURL = [fileNameArr objectAtIndex: 0];
    NSString *thumbURL = [fileNameArr objectAtIndex: 1];
    
    int burnMessage = [AppUtils getBurnMessageValueOfRemoteParty: remoteParty];
    [NSDatabase saveMessage:USERNAME toPhone:remoteParty withContent:@"" andStatus:NO withDelivered:delivered andIdMsg:idMsgImage detailsUrl:detailURL andThumbUrl:thumbURL withTypeMessage:imageMessage andExpireTime:burnMessage andRoomID:@"" andExtra:nil andDesc:appDelegate.titleCaption];
    
    //  Upload image lên server
    [self startUploadImage:captureImage toServerWithMessageId:idMsgImage andName:detailURL];
}

@end
