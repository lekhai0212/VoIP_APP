//
//  MoreViewController.h
//  linphone
//
//  Created by user on 1/7/14.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"

enum moreValue{
    eRingtone,
    eCallSettings,
    eAppInfo,
    eSendLogs,
    eSignOut,
    ePrivayPolicy,
    eIntroduction,
};

enum stateLogout {
    eRemoveTokenSIP = 1,
    eRemoveTokenPBX
};

@interface MoreViewController : UIViewController<UICompositeViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *_viewHeader;
@property (weak, nonatomic) IBOutlet UIImageView *bgHeader;
@property (weak, nonatomic) IBOutlet UIImageView *_imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *_lbName;
@property (weak, nonatomic) IBOutlet UILabel *lbPBXAccount;
@property (weak, nonatomic) IBOutlet UITableView *_tbContent;

@end
