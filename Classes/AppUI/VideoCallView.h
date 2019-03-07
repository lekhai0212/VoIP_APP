//
//  VideoCallView.h
//  linphone
//
//  Created by lam quang quan on 3/4/19.
//

#import <UIKit/UIKit.h>
#import "UICamSwitch.h"

@interface VideoCallView : UIView

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *previewVideo;
@property (weak, nonatomic) IBOutlet UICamSwitch *iconSwitchCam;
@property (weak, nonatomic) IBOutlet UIButton *iconHangup;
@property (weak, nonatomic) IBOutlet UILabel *lbDuration;
@property (weak, nonatomic) IBOutlet UILabel *lbQuality;
@property (weak, nonatomic) IBOutlet UIButton *iconOffCamera;
@property (weak, nonatomic) IBOutlet UIButton *iconMute;

@property (nonatomic, strong) NSTimer *qualityTimer;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *icWaitVideoCamera;

- (void)setupUIForView;
- (void)registerNotifications;
- (IBAction)iconOffCameraClick:(UIButton *)sender;
- (IBAction)iconMuteClick:(UIButton *)sender;
- (IBAction)iconWtitchCamClick:(UIButton *)sender;
- (void)testChangeCamera;
- (IBAction)iconHangupClick:(UIButton *)sender;

@end
