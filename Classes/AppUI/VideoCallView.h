//
//  VideoCallView.h
//  linphone
//
//  Created by lam quang quan on 3/4/19.
//

#import <UIKit/UIKit.h>

@interface VideoCallView : UIView

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *previewVideo;
@property (weak, nonatomic) IBOutlet UIButton *iconSwitchCam;
@property (weak, nonatomic) IBOutlet UIHangUpButton *iconHangup;
@property (weak, nonatomic) IBOutlet UILabel *lbDuration;
@property (weak, nonatomic) IBOutlet UILabel *lbQuality;
@property (weak, nonatomic) IBOutlet UIButton *iconOffCamera;
@property (weak, nonatomic) IBOutlet UIButton *iconMute;

@property (nonatomic, strong) NSTimer *qualityTimer;
@property (nonatomic, strong) NSTimer *durationTimer;

- (void)setupUIForView;
- (void)registerNotifications;

@end
