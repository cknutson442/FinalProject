#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface GroupViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    double _min, _max;
    __weak IBOutlet UISlider *_slider;
    __weak IBOutlet UILabel *_labelValue;
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *tempImageView;
@property (strong, nonatomic) IBOutlet UILabel *objectSizeLabel;
- (IBAction)pickImageFromGallery:(id)sender;
- (IBAction)takePictureFromCamera:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;

@end
