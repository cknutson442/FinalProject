#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface GroupViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    double _min, _max;
    __weak IBOutlet UILabel *_labelValue;
    UIImageView *img;
    int counter;
    CGPoint location;

    NSMutableArray *coordinates;
    NSMutableArray *shotDistances;

    __weak IBOutlet UIButton *addShotsButton;
    __weak IBOutlet UIButton *setMarkerButton;
    __weak IBOutlet UIButton *deleteCurrentButton;
    __weak IBOutlet UIButton *calculateScoreButton;
    CGFloat distance;
    int radiusDistanceConverted;
    CGPoint phoneCenter;
    CGFloat totalScore;
    __weak IBOutlet UILabel *pointsLabel;
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *objectSizeLabel;

- (IBAction)pickImageFromGallery:(id)sender;
- (IBAction)takePictureFromCamera:(id)sender;
- (IBAction)addShots;
- (IBAction)saveImage;
- (IBAction)setMarker;
- (IBAction)deleteCurrentMarker;
- (IBAction)calculate;

@end
