#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"

#import "AppDelegate.h"
#import "GroupViewController.h"
#import "Score.h"

using namespace std;
using namespace cv;

@interface GroupViewController ()
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;

@end

@implementation GroupViewController

UIImageOrientation orientation;
cv::Mat imageMat;
cv::Mat imageMat2;

cv::vector<cv::Mat> BGR;
CGPoint lastPoint = {-1,-1};
CGPoint minPoint = {9999,9999}, maxPoint = {-1,-1};
bool mouseSwiped;

IplImage* iplImage;
UIImage* image2;
cv::vector<cv::Vec3f>circles;
float radius;

//Circle::Circle(cv::Mat imageMat,Point const& width, Point const& height);

- (void)viewDidLoad{
    [super viewDidLoad];
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    counter = 0;
    
    coordinates = [[NSMutableArray alloc] init];
    
    [addShotsButton setEnabled:YES];
    [setMarkerButton setEnabled:NO];
    [deleteCurrentButton setEnabled:NO];
    
    _labelValue.text = [NSString stringWithFormat:@"%.2f - %.2f", _min, _max];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    
    [picker dismissModalViewControllerAnimated:YES];

    imageMat = [self cvMatFromUIImage:image];
    cvtColor(imageMat, imageMat2, CV_RGB2GRAY);

    GaussianBlur(imageMat2, imageMat2, cv::Size(9,9),2,2);
    
    //HoughCircles(imageMat2, circles, CV_HOUGH_GRADIENT, 2,10,32,200,0,0);
    HoughCircles(imageMat2, circles, CV_HOUGH_GRADIENT, 2, imageMat2.rows/4, 100, 200,0,0);
    //HoughCircles(imageMat2, circles, CV_HOUGH_GRADIENT, 1, imageMat2.rows/4 ,200,100,0,0);

    NSLog(@"imageMat2.row/4:%d ",imageMat2.rows/4);
    //NSLog(@"imagemat size:%@",imageMat.size);
    
    NSLog(@"%lu",circles.size());
    
    
        for(size_t i = 0; i < circles.size(); i++)
        {
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            int radius = cvRound(circles[i][2]);
            // circle center
            circle( imageMat, center, 3, Scalar(0,255,0), -1, 8, 0 );
            // circle outline
            circle( imageMat, center, radius, Scalar(0,0,255), 3, 8, 0 );

            NSLog(@"centerX:%f centerY:%f radius:%d",circles[i][0],circles[i][1],radius);
            
            NSLog(@"new Radius:%f",.132*radius);
            //(x+r,y)

            
        }
    
    _imageView.image = [self UIImageFromCVMat:imageMat];
    [addShotsButton setEnabled:YES];

    
}

- (IBAction)pickImageFromGallery:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)takePictureFromCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera Available" message:@"Make sure that your camera is working." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil,nil];
        [alert show];
    }
}

- (IBAction)addShots {
    
    NSLog(@"add");
    [deleteCurrentButton setEnabled:YES];
    [setMarkerButton setEnabled:YES];
    [addShotsButton setEnabled:NO];

    //enable done button and delete current
    
    UIImage *bulletMark = [UIImage imageNamed:@"x-1.png"];
    img = [[UIImageView alloc] initWithImage:bulletMark];
    [self.imageView addSubview:img];
    
    float radX = circles[0][0];
    radX = (radX -radius)*(432.0/3264.0);
    float radY = circles[0][1];
    radY = radY*(320.0/2448.0);
    

    float centerX = circles[0][0];
    centerX = centerX*(432.0/3264.0);
    float centerY = circles[0][1];
    centerY = centerY*(320.0/2448.0);
    
    
    CGFloat pointToRadiusX = radX - centerX;
    CGFloat pointToRadiusY = radY - centerY;
    CGFloat radiusDistance = sqrt((pointToRadiusX*pointToRadiusX)+(pointToRadiusY*pointToRadiusY));
    
    [radii addObject:@(radiusDistance)];
    NSLog(@"centerX:%f centerY:%f radiusDistance:%f",centerX,centerY,radiusDistance);
    
    
    img.center = CGPointMake(320-centerY, centerX);
}

- (IBAction)saveImage {
    
    NSLog(@"SAVE");
    
    UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, NO, 0);

    [self.imageView drawViewHierarchyInRect:self.imageView.bounds afterScreenUpdates:YES];
    
    UIImage *copied = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(copied,nil, nil, nil) ;

}


- (IBAction)deleteCurrentMarker {
    NSLog(@"delete");
    [deleteCurrentButton setEnabled:NO];
    [setMarkerButton setEnabled:NO];
    [addShotsButton setEnabled:YES];

    [img removeFromSuperview];

}


- (IBAction)setMarker {
    [coordinates addObject:[NSValue valueWithCGPoint:location]];
    [deleteCurrentButton setEnabled:NO];
    [setMarkerButton setEnabled:NO];
    [addShotsButton setEnabled:YES];

    NSLog(@"set");

}

- (IBAction) calculate {
    NSUInteger count = [coordinates count];
    distance = 0;
    counter=0;
    NSLog(@"array count: %lu",(unsigned long)count);
    
    for (int i = 0; i < count; i++) {
        NSValue *pointLocation = [coordinates objectAtIndex:i];
        CGPoint tempPoint = [pointLocation CGPointValue];

        for(int j = i +1 ; j < count; j++ )
        {
            counter++;
            NSLog(@"counter: %d",counter);
       
            NSValue *nextPointLocation = [coordinates objectAtIndex:j];
            CGPoint nextPoint = [nextPointLocation CGPointValue];
        
        
            CGFloat xDist = (nextPoint.x - tempPoint.x);
            CGFloat yDist = (nextPoint.y - tempPoint.y);
            CGFloat tempDistance = sqrtf((xDist * xDist) + (yDist * yDist));
            
            if (distance == 0 || tempDistance > distance)
            {
                distance = tempDistance;
            }
            NSLog(@"i value:%d point1:%@ point2:%@ disance:%f",i,pointLocation,nextPointLocation,distance);
        }
    }
    NSLog(@"disance:%f",distance);
    [self saveScore];
}

- (void) saveScore {
    Score * score = [NSEntityDescription insertNewObjectForEntityForName:@"Score"
                                                      inManagedObjectContext:self.managedObjectContext];
    
    score.name = @"Hunter";
    //score.score = @(distance);
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    [self.view endEditing:YES];
}
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	location = [touch locationInView:_imageView];
	img.center = location;
    NSLog(@"location: %@",NSStringFromCGPoint(location));
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}































- (cv::Mat)cvMatFromUIImage:(UIImage *)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    orientation = image.imageOrientation;
    NSLog(@"orientation %ld -- %ld", image.imageOrientation, UIImageOrientationUp);
    CGFloat cols,rows;
    if(orientation == UIImageOrientationUp){
        cols = image.size.width;
        rows = image.size.height;
    }
    else{
        
        cols = image.size.height;
        rows = image.size.width;

    }
    
    NSLog(@"width: @%f height: @%f", cols, rows);
    
    medianBlur(imageMat,imageMat,5);
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}








-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    //UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
