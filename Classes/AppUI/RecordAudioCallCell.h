//
//  RecordAudioCallCell.h
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import <UIKit/UIKit.h>

@interface RecordAudioCallCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@property (weak, nonatomic) IBOutlet UIButton *btnChoose;
@property (weak, nonatomic) IBOutlet UILabel *lbSepa;

@end
