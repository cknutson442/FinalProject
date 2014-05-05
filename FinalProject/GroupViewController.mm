#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"

#import "GroupViewController.h"

using namespace std;
using namespace cv;

@interface GroupViewController ()

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


//Circle::Circle(cv::Mat imageMat,Point const& width, Point const& height);

- (void)viewDidLoad{
    [super viewDidLoad];
    
    
    
    _labelValue.text = [NSString stringWithFormat:@"%.2f - %.2f", _min, _max];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    [picker dismissModalViewControllerAnimated:YES];
    
    //    medianBlur(imageMat,imageMat,5);
    //
    //    imageMat = [self cvMatFromUIImage:image];
    //    //    cvtColor(img, cimg, COLOR_GRAY2BGR);
    //    cvtColor(imageMat, imageMat2, CV_RGB2GRAY);
    //
    //
    //    //split(imageMat,BGR);
    //
    //    cv::vector<cv::Vec3f>circles;
    //    HoughCircles(imageMat2, circles, CV_HOUGH_GRADIENT, 1, 10,
    //                 100, 30, 1, 30
    //
    //                 );
    //
    //    for(size_t i = 0; i < circles.size(); i++)
    //    {
    ////        Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
    //        int radius = cvRound(circles[i][2]);
    ////        // circle center
    ////        circle( src, center, 3, Scalar(0,255,0), -1, 8, 0 );
    ////        // circle outline
    ////        circle( src, center, radius, Scalar(0,0,255), 3, 8, 0 );
    ////        cv::Vec3i c = circles[i];
    ////        circle( imageMat2, Point(c[0], c[1]), c[2], Scalar(0,0,255), 3, LINE_AA);
    ////        circle( imageMat2, Point(c[0], c[1]), 2, Scalar(0,255,0), 3, LINE_AA);
    //
    //        NSLog(@"%d",radius);
    //
    //    }
    
    //_imageView.image = [self UIImageFromCVMat:imageMat];
    iplImage =[self CreateIplImageFromUIImage:image];
    [self didCaptureIplImage:iplImage];
    
    //image2 = [ self UIImageFromIplImage:iplImage];
    //_imageView.image = image2;
    
    
}

- (IBAction)sliderValueChanged:(id)sender {
    double rangeMIN = 0;
    double rangeMAX = 180;
    double step = 10;
    
    _min = rangeMIN + _slider.value * (rangeMAX - rangeMIN - step);
    _max = _min + step;
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



static BOOL _debug = NO;

- (void)didCaptureIplImage:(IplImage *)iplImage
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
    cv::Mat matRGB = cv::Mat(imgRGB);
    
    //ipl imaeg is also converted to HSV; hue is used to find certain color
    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);
    
    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);
    
    //it is important to release all images EXCEPT the one that is going to be passed to
    //the didFinishProcessingImage: method and displayed in the UIImageView
    cvReleaseImage(&iplImage);
    
    //filter all pixels in defined range, everything in range will be white, everything else
    //is going to be black
    cvInRangeS(imgHSV, Scalar(0, 0, 0), Scalar(_max, 0, 0), imgThreshed);
    cvReleaseImage(&imgHSV);
    
    Mat matThreshed = Mat(imgThreshed);
    
    //smooths edges
    cv::GaussianBlur(matThreshed,
                     matThreshed,
                     cv::Size(9, 9),
                     2,
                     2);
    
    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
    if (_debug)
    {
        cvReleaseImage(&imgRGB);
        //        _imageView.image = [self UIImageFromIplImage:imgThreshed];
        
        Mat coba(imgThreshed);
        _imageView.image = [self UIImageFromCVMat:matThreshed];
        
        //[self didFinishProcessingImage:imgThreshed];
    }
    else
    {
        vector<Vec3f> circles;
        
        //get circles
        HoughCircles(matThreshed,
                     circles,
                     CV_HOUGH_GRADIENT,
                     1,
                     1,
                     150,
                     31,
                     0,
                     0);
        
        NSLog(@"%lu",circles.size());
        
        for (size_t i = 0; i < circles.size(); i++)
        {
            //            cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            //                    NSLog(@"%d",radius);
            
            circle(matRGB, center, 3, Scalar(0, 255, 0), -1, 8, 0);
            circle(matRGB, center, radius, Scalar(0, 0, 255), 3, 8, 0);
        }
        
        //threshed image is not needed any more and needs to be released
        cvReleaseImage(&imgThreshed);
        
        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
        //method will take care of that
        //[self didFinishProcessingImage:imgRGB];
        
        _imageView.image = [self UIImageFromIplImage:imgRGB];
    }
}

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    orientation = image.imageOrientation;
    CGFloat cols,rows;
    if(orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight){
        cols = image.size.width;
        rows = image.size.height;
    }
    else{
        cols = image.size.height;
        rows = image.size.width;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(cols,rows), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    
    
    
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}


















- (cv::Mat)cvMatFromUIImage:(UIImage *)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    orientation = image.imageOrientation;
    CGFloat cols,rows;
    if(orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight){
        cols = image.size.height;
        rows = image.size.width;
    }
    else{
        cols = image.size.width;
        rows = image.size.height;
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

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [touches anyObject];
//
//    if ([touch view] == _tempImageView)
//    {
//        //getPosition
//        CGPoint touchPoint = [touch locationInView:_tempImageView];
//
//        //conditioning if pixel is an edge
//        if ([self checkEdge:touchPoint kernelSize:5]) {
//            //            _statusClick.text = @"clickable";
//            lastPoint = touchPoint;
//        }
//        else{
//            //            _statusClick.text = @"no";
//        }
//    }
//    mouseSwiped = NO;
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//
//    mouseSwiped = YES;
//    UITouch *touch = [touches anyObject];
//    CGPoint currentPoint = [touch locationInView:_tempImageView];
//
//    if (lastPoint.x == -1) {
//        lastPoint = currentPoint;
//    }
//    else{
//        if ([self checkEdge:currentPoint kernelSize:5] and [self isNeighbor:currentPoint to:lastPoint kernelSize:15]){
//            UIGraphicsBeginImageContext(self.tempImageView.frame.size);
//            [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.frame.size.width, self.tempImageView.frame.size.height)];
//            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
//            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
//            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
//            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5 );
//            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 255, 0, 0, 1.0);
//            CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
//
//            CGContextStrokePath(UIGraphicsGetCurrentContext());
//            self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext();
//            [self.tempImageView setAlpha:1];
//            UIGraphicsEndImageContext();
//            lastPoint = currentPoint;
//            [self checkMaxMinPoint:currentPoint];
//        }
//    }
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//
//    if(!mouseSwiped) {
//        UIGraphicsBeginImageContext(self.tempImageView.frame.size);
//        [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.frame.size.width, self.tempImageView.frame.size.height)];
//        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
//        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5);
//        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 255, 0, 0, 1);
//        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
//        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
//        CGContextStrokePath(UIGraphicsGetCurrentContext());
//        CGContextFlush(UIGraphicsGetCurrentContext());
//        self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
//
//    UIGraphicsBeginImageContext(self.imageView.frame.size);
//    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
//    [self.tempImageView.image drawInRect:CGRectMake(0, 0, self.tempImageView.image.size.width, self.tempImageView.image.size.height) blendMode:kCGBlendModeNormal alpha:1];
//    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
//    self.tempImageView.image = nil;
//    UIGraphicsEndImageContext();
//    
//    lastPoint = {-1,-1};
//}

@end
