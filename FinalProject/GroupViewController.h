//
//  ViewController.h
//  FinalProject
//
//  Created by CONNER KNUTSON on 3/26/14.
//  Copyright (c) 2014 CONNER KNUTSON. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface GroupViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *tempImageView;
@property (strong, nonatomic) IBOutlet UILabel *objectSizeLabel;
- (IBAction)pickImageFromGallery:(id)sender;
- (IBAction)takePictureFromCamera:(id)sender;

@end
