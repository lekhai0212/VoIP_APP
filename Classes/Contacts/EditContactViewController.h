//
//  EditContactViewController.h
//  linphone
//
//  Created by Ei Captain on 4/4/17.
//
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "ContactObject.h"

@interface EditContactViewController : UIViewController<UICompositeViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *_viewHeader;
@property (weak, nonatomic) IBOutlet UIImageView *bgHeader;
@property (weak, nonatomic) IBOutlet UIButton *_iconBack;
@property (weak, nonatomic) IBOutlet UILabel *_lbHeader;
@property (weak, nonatomic) IBOutlet UIImageView *_imgAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *_imgChangePicture;
@property (weak, nonatomic) IBOutlet UIButton *_btnAvatar;

@property (weak, nonatomic) IBOutlet UITableView *tbContents;

- (IBAction)_iconBackClicked:(UIButton *)sender;
- (IBAction)_btnAvatarPressed:(UIButton *)sender;

@property (nonatomic, strong) ContactObject *detailsContact;

@property (nonatomic, assign) int idContact;
@property (nonatomic, strong) NSString *curPhoneNumber;

@end
