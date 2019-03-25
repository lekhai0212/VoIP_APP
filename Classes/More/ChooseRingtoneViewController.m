//
//  ChooseRingtoneViewController.m
//  linphone
//
//  Created by lam quang quan on 3/14/19.
//

#import "ChooseRingtoneViewController.h"
#import "ChooseRingToneCell.h"
#import "PlayRingTonePopupView.h"

@interface ChooseRingtoneViewController ()<UITableViewDelegate, UITableViewDataSource, PlayRingTonePopupViewDelegate>{
    NSMutableArray *ringtones;
}

@end

@implementation ChooseRingtoneViewController
@synthesize viewHeader, bgHeader, iconBack, lbTitle, tbList;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self autoLayoutForView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self getListRingTonesFromFile];
    
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iconBackClick:(UIButton *)sender {
    [[PhoneMainView instance] popCurrentView];
}

- (void)autoLayoutForView {
    float hHeader = [LinphoneAppDelegate sharedInstance]._hRegistrationState;
    [viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewHeader);
    }];
    
    if (SCREEN_WIDTH > 320) {
        iconBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }else{
        iconBack.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
    }
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.left.equalTo(viewHeader);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    lbTitle.font = [LinphoneAppDelegate sharedInstance].headerFontNormal;
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.bottom.equalTo(viewHeader);
        make.centerX.equalTo(viewHeader.mas_centerX);
        make.width.mas_equalTo(250);
    }];
    
    tbList.separatorStyle = UITableViewCellSelectionStyleNone;
    tbList.delegate = self;
    tbList.dataSource = self;
    [tbList mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)getListRingTonesFromFile {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"RingTone"
                                                         ofType:@"plist"];
    NSArray *plist = [NSArray arrayWithContentsOfFile: filePath];
    if (ringtones == nil) {
        ringtones = [[NSMutableArray alloc] init];
    }
    [ringtones removeAllObjects];
    
    if (plist != nil) {
        [ringtones addObjectsFromArray: plist];
    }
}

- (void)finishedSetRingTone:(NSString *)ringtone {
    [tbList reloadData];
    [LinphoneManager.instance startLinphoneCore];
    [LinphoneManager.instance.providerDelegate config];
}

#pragma mark - UITableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ringtones.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ChooseRingToneCell";
    ChooseRingToneCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ChooseRingToneCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSString *curRingTone = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_RINGTONE];
    
    if (indexPath.row == 0) {
        cell.lbName.text = [[LanguageUtil sharedInstance] getContent:@"Silent"];
        cell.imgRingTone.image = [UIImage imageNamed:@"no_sound"];
        
        if ([curRingTone isEqualToString:@"silence.mp3"]) {
            cell.imgSelected.hidden = NO;
        }else{
            cell.imgSelected.hidden = YES;
        }
    }else{
        NSDictionary *ringtone = [ringtones objectAtIndex: (indexPath.row-1)];
        NSString *name = [ringtone objectForKey:@"name"];
        cell.lbName.text = name;
        cell.imgRingTone.image = [UIImage imageNamed:@"more_ringtone"];
        
        NSString *file = [ringtone objectForKey:@"file"];
        if ([file isEqualToString: curRingTone]) {
            cell.imgSelected.hidden = NO;
        }else{
            cell.imgSelected.hidden = YES;
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:SILENCE_RINGTONE forKey:DEFAULT_RINGTONE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self finishedSetRingTone: SILENCE_RINGTONE];
    }else{
        float hPopup = 15 + 40.0 + 15.0 + 50.0;
        PlayRingTonePopupView *popupRingTone = [[PlayRingTonePopupView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-300.0)/2, (SCREEN_HEIGHT-hPopup)/2, 300.0, hPopup)];
        popupRingTone.delegate = self;
        [popupRingTone showInView:self.view animated:YES];
        
        NSDictionary *ringtone = [ringtones objectAtIndex: (indexPath.row-1)];
        [popupRingTone setRingtoneInfoContent: ringtone];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}


@end
