//
//  GroupViewController.m

//

#import "GroupViewController.h"

//using namespace std;
//using namespace cv;

@interface GroupViewController ()

@end

@implementation GroupViewController

cv::Mat imageMat;
cv::vector<cv::Mat> BGR;
CGPoint lastPoint = {-1,-1};
CGPoint minPoint = {9999,9999}, maxPoint = {-1,-1};
bool mouseSwiped;

- (void)viewDidLoad{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    [picker dismissModalViewControllerAnimated:YES];
    imageMat = [self cvMatFromUIImage:image];
    cv::cvtColor(imageMat, imageMat, CV_RGB2GRAY);
    
    //the line detection process is here
    cv::Canny(imageMat, imageMat, 35, 90);
    
    split(imageMat,BGR);
    
    _imageView.image = [self UIImageFromCVMat:imageMat];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera Available" message:@"Make sure that your camera is working or contacts apple store." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil,nil];
        [alert show];
    }
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
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
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

-(bool)checkEdge:(CGPoint)point kernelSize:(int)kSize{
    int pixelTaken;
    int iter = kSize/2;
    for (int i=-iter; i<=iter; i++) {
        for (int j=-iter; j<=iter; j++) {
            pixelTaken = (int)BGR[0].at<uchar>(point.y+i, point.x+j);
            //                NSLog(@"%d",pixelTaken);
            if(pixelTaken > 0){
                return YES;
            }
        }
    }
    return NO;
}

-(void)checkMaxMinPoint:(CGPoint)currentPoint{
    minPoint.x = fmin(minPoint.x, currentPoint.x);
    minPoint.y = fmin(minPoint.y, currentPoint.y);
    maxPoint.x = fmax(maxPoint.x, currentPoint.x);
    maxPoint.y = fmax(maxPoint.y, currentPoint.y);
    
    double width = maxPoint.x - minPoint.x;
    double height = maxPoint.y - minPoint.y;
    
    _objectSizeLabel.text = [NSString stringWithFormat:@"%.0f X %.0f", width,height];
}

-(bool)isNeighbor:(CGPoint)source to:(CGPoint)destination kernelSize:(int)kSize{
    return sqrt(pow(destination.x - source.x, 2) + pow(destination.y - source.y, 2)) <= (kSize/2);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    
    if ([touch view] == _tempImageView)
    {
        //getPosition
        CGPoint touchPoint = [touch locationInView:_tempImageView];
        
        //conditioning if pixel is an edge
        if ([self checkEdge:touchPoint kernelSize:5]) {
            //            _statusClick.text = @"clickable";
            lastPoint = touchPoint;
        }
        else{
            //            _statusClick.text = @"no";
        }
    }
    mouseSwiped = NO;}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:_tempImageView];
    
    if (lastPoint.x == -1) {
        lastPoint = currentPoint;
    }
    else{
        if ([self checkEdge:currentPoint kernelSize:5] and [self isNeighbor:currentPoint to:lastPoint kernelSize:15]){
            UIGraphicsBeginImageContext(self.tempImageView.frame.size);
            [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.frame.size.width, self.tempImageView.frame.size.height)];
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5 );
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 255, 0, 0, 1.0);
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
            
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            [self.tempImageView setAlpha:1];
            UIGraphicsEndImageContext();
            lastPoint = currentPoint;
            [self checkMaxMinPoint:currentPoint];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!mouseSwiped) {
        UIGraphicsBeginImageContext(self.tempImageView.frame.size);
        [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.frame.size.width, self.tempImageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 255, 0, 0, 1);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContext(self.imageView.frame.size);
    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.image.size.width, self.tempImageView.image.size.height) blendMode:kCGBlendModeNormal alpha:1];
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    self.tempImageView.image = nil;
    UIGraphicsEndImageContext();
    
    lastPoint = {-1,-1};
}

@end
