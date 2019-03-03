//
//  AudioCallView.h
//  linphone
//
//  Created by admin on 3/3/19.
//

#import <UIKit/UIKit.h>
#import "PulsingHaloLayer.h"
#import "UIMutedMicroButton.h"
#import "UISpeakerButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioCallView : UIView<UIMutedMicroButtonDelegate, UISpeakerButtonDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *bgCall;
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@property (weak, nonatomic) IBOutlet UILabel *lbDuration;
@property (weak, nonatomic) IBOutlet UILabel *lbQuality;
@property (weak, nonatomic) IBOutlet UIButton *iconEndCall;
@property (weak, nonatomic) IBOutlet UISpeakerButton *iconSpeaker;
@property (weak, nonatomic) IBOutlet UIMutedMicroButton *iconMute;
@property (nonatomic, weak) PulsingHaloLayer *halo;
@property (nonatomic, strong) NSTimer *qualityTimer;
@property (nonatomic, strong) NSTimer *durationTimer;
- (IBAction)iconEndCallClick:(UIButton *)sender;

- (void)setupUIForView;
- (void)registerNotifications;
- (void)updatePositionHaloView;


@property(nonatomic, assign) float hLabel;
@property(nonatomic, assign) float padding;
@property(nonatomic, assign) float hAvatar;
@property(nonatomic, assign) float paddingYAvatar;
@property(nonatomic, assign) BOOL needEnableSpeaker;

@end

NS_ASSUME_NONNULL_END
