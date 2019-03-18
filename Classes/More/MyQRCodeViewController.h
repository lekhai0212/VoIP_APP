//
//  MyQRCodeViewController.h
//  linphone
//
//  Created by lam quang quan on 3/18/19.
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"

@interface MyQRCodeViewController : UIViewController<UICompositeViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIImageView *imgHeader;
@property (weak, nonatomic) IBOutlet UIButton *iconBack;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
- (IBAction)iconBackClick:(UIButton *)sender;
- (IBAction)icSaveClick:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIButton *icSave;
- (IBAction)icSaveClicked:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imgMyQRCode;

@end
