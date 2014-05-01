//
//  ShotTimerViewController2.m
//  FinalProject
//
//  Created by CONNER KNUTSON on 3/26/14.
//  Copyright (c) 2014 CONNER KNUTSON. All rights reserved.
//

#import "ShotTimerViewController2.h"
#import "Novocaine.h"
#import "AudioFileReader.h"
#import "RingBuffer.h"
#import "SMUGraphHelper.h"
#import "SMUFFTHelper.h"

#define kBufferLength2 4096
#define localMaxWindowSize2 7

#define magValue 20
#define magTolerance 5
#define freqValue 700
#define freqTolerance 100


@interface ShotTimerViewController2 ()
//@property (weak, nonatomic) IBOutlet UILabel *freqLabel;
//@property (weak, nonatomic) IBOutlet UILabel *magLabel;
//@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel2;

@end

@implementation ShotTimerViewController2

@synthesize timerLabel2;


Novocaine *audioManager2;
AudioFileReader *fileReader2;
RingBuffer *ringBuffer2;
GraphHelper *graphHelper2;
float *audioData2;
SMUFFTHelper *fftHelper2;
float *fftMagnitudeBuffer2;
float *fftMagnitudeBufferdB2;
float *fftPhaseBuffer2;
float loudestShot2;

int milliseconds2 = 0;
int seconds2 = 0;
int minutes2 = 0;


//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)startTimerMethod {
    timer2 = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(ticker2:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer2 forMode:NSDefaultRunLoopMode];
}

- (IBAction)stopTimer:(id)sender {
    [timer2 invalidate];
}

//- (void)transition {
//    [self performSegueWithIdentifier:@"secondScreen" sender:self];
//}

- (void)ticker2:(NSTimer *)timer2 {
    
    //NSLog(@"Ticking...");
    
    if(seconds2 == 59 && milliseconds2 == 999)
    {
        seconds2 = 0;
        milliseconds2 = 0;
        minutes2++;
    }
    else if(milliseconds2 == 999)
    {
        milliseconds2 = 0;
        seconds2++;
    }
    else
    {
        milliseconds2++;
    }
    
    
    //    if (seconds == 0 && minutes >= 1)
    //    {
    //        seconds = 59;
    //        minutes--;
    //
    //    }
//    if (minutes ==0 && seconds ==0)
//    {
//        [self stopTimer:nil];
//        [self transition];
//        
//        //timerLabel.text = @"00:00";
//    } else {
//        seconds--;
//    }
    
    NSString* currentTime2 = [NSString stringWithFormat:@"%02d.%03d",seconds2,milliseconds2];
    //NSLog(@"%@",currentTime2);
    timerLabel2.text = currentTime2;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //graphHelper2->tearDownGL();

    
    audioManager2 = [Novocaine audioManager];
    ringBuffer2 = new RingBuffer(kBufferLength2,2);
    
    audioData2 = (float*)calloc(kBufferLength2,sizeof(float));
    
    //setup the fft
    fftHelper2 = new SMUFFTHelper(kBufferLength2,kBufferLength2,WindowTypeRect);
    fftMagnitudeBuffer2 = (float *)calloc(kBufferLength2/2,sizeof(float));
    fftMagnitudeBufferdB2 = (float *)calloc(kBufferLength2/2,sizeof(float));
    fftPhaseBuffer2     = (float *)calloc(kBufferLength2/2,sizeof(float));
    
    
    // start animating the graph
    int framesPerSecond = 30;
    int numDataArraysToGraph = 2;
    graphHelper2 = new GraphHelper(self,
                                  framesPerSecond,
                                  numDataArraysToGraph,
                                  PlotStyleSeparated);//drawing starts immediately after call
    
    graphHelper2->SetBounds(-0.5,0.9,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)

    [audioManager2 setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(ringBuffer2!=nil)
             ringBuffer2->AddNewFloatData(data, numFrames);
     }];
    
    minutes2 = 0;
    seconds2 = 0;
    milliseconds2 = 0;
    
    [self stopTimer:nil];
    
    [self startTimerMethod];
    
    NSLog(@"\n\nPassed in values:\nMag: %.2f Freq: %.2f\n\n",_magVal,_freqVal);
    
}

#pragma mark - unloading and dealloc
-(void) viewDidDisappear:(BOOL)animated{
    // stop opengl from running
    graphHelper2->tearDownGL();
    //graphHelper2->tearDownGL();
    
    free(audioData2);
    
    free(fftMagnitudeBuffer2);
    free(fftMagnitudeBufferdB2);
    free(fftPhaseBuffer2);
    
    delete fftHelper2;
    delete ringBuffer2;
    delete graphHelper2;
    
    ringBuffer2 = nil;
    fftHelper2  = nil;
    audioManager2 = nil;
    graphHelper2 = nil;
    
    minutes2 = 0;
    seconds2 = 0;
    milliseconds2 = 0;
    
    [self stopTimer:nil];

}

-(void)dealloc{
    
    //graphHelper2->tearDownGL();

        
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    
}

//#pragma mark - OpenGL and Update functions
//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    graphHelper2->draw(); // draw the graph
}

//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    //NSLog(@"Update function");
    
    // plot the audio
    ringBuffer2->FetchFreshData2(audioData2, kBufferLength2, 0, 1);
    graphHelper2->setGraphData(0,audioData2,kBufferLength2); // set graph channel
    
    //take the FFT
    fftHelper2->forward(0,audioData2, fftMagnitudeBuffer2, fftPhaseBuffer2);
    
    //Analyze the FFT
    //get the index value of 500Hz and only look at above that
    //k(Fs/N)=500 => k=500(N/Fs) where N is buffer length and Fs 44100
    int minFreqIndexb = 500 * (kBufferLength2/audioManager2.samplingRate);
    //create variables for holding the two loudest frequencies and their indices
    float mag1b = 0;
    int ind1b = 0;
    //    float mag2 = 0;
    //    int ind2 = 0;
    float magTempb = 0;
    int indTempb = 0;
    //outer loop to go through fft
    for(int n = minFreqIndexb; n < kBufferLength2/2-localMaxWindowSize2; n++)
    {
        //reset temp variables to zero
        magTempb = 0;
        indTempb = 0;
        
        //inner loop to go through current window
        for(int m = n; m <= n+localMaxWindowSize2; m++)
        {
            //find max in current window
            if(fftMagnitudeBuffer2[m] > magTempb)
            {
                magTempb = fftMagnitudeBuffer2[m];
                indTempb = m;
            }
        }
        //is max in window the middle value?
        if(indTempb == (n+localMaxWindowSize2/2))
        {
            //loudest tone
            if(fftMagnitudeBuffer2[indTempb] > fftMagnitudeBuffer2[ind1b])
            {
                //                mag2 = mag1;
                //                ind2 = ind1;
                mag1b = fftMagnitudeBuffer2[indTempb];
                ind1b = indTempb;
                
            }
            //second loudest tone
            //            else if(fftMagnitudeBuffer[indTemp] > fftMagnitudeBuffer[ind2])
            //            {
            //                mag2 = fftMagnitudeBuffer[indTemp];
            //                ind2 = indTemp;
            //
            //            }
        }
    }
    
    
    
    
    
    
    //here I want to convert the magnitude into decibels!
    float x = 1;
    vDSP_vdbcon(fftMagnitudeBuffer2, 1, &x, fftMagnitudeBufferdB2, 1, kBufferLength2/2, 0);
    loudestShot2 = fftMagnitudeBufferdB2[ind1b];
    //NSLog(@"%.2f",loudestShot2);
    
    
    //NSLog(@"if statement");
    //NSLog(@"The loudest frequency is: %.2f Hz with magnitude %.2f dB",(ind1b*(audioManager2.samplingRate/kBufferLength2)),loudestShot2);
    //NSLog(@"%d     %.2f     %d",magValue-magTolerance,loudestShot2,magValue+magTolerance);
    //NSLog(@"%d     %.2f     %d",freqValue-freqTolerance,(ind1b*(audioManager2.samplingRate/kBufferLength2)),freqValue+freqTolerance);
    if((loudestShot2>_magVal-magTolerance && loudestShot2<_magVal+magTolerance) && ((ind1b*(audioManager2.samplingRate/kBufferLength2))>_freqVal-freqTolerance && (ind1b*(audioManager2.samplingRate/kBufferLength2))<_freqVal+freqTolerance))
    {
        NSLog(@"The frequency in range is: %.2f Hz with magnitude %.2f dB",(ind1b*(audioManager2.samplingRate/kBufferLength2)),loudestShot2);
        [self stopTimer:nil];
        timerLabel2.text = [NSString stringWithFormat:@"00.000"];
        minutes2 = 0;
        seconds2 = 0;
        milliseconds2 = 0;
        [self startTimerMethod];
    }
    
    
    
    /*if(loudestShot2 > 20.0)
    {
        NSLog(@"The loudest frequency is: %.2f Hz with magnitude %.2f dB",(ind1b*(audioManager2.samplingRate/kBufferLength2)),loudestShot2);
//        _freqLabel.text = [NSString stringWithFormat:@"%.2f Hz",ind1*(audioManager2.samplingRate/kBufferLength2)];
//        _magLabel.text = [NSString stringWithFormat:@"%.2f dB",loudestShot2];
        //_firstValue.text = [NSString stringWithFormat:@"%.2f",ind1*(audioManager.samplingRate/kBufferLength)];
        
        //NSLog(@"The loudest frequency is: %.2f dB",magTemp);
        //make a label to display on screen the loudest magnitude
        
        //        NSLog(@"The second loudest frequency is: %.2f Hz",(ind2*(audioManager.samplingRate/kBufferLength)));
        //        _secondValue.text = [NSString stringWithFormat:@"%.2f",ind2*(audioManager.samplingRate/kBufferLength)];
    }*/
    
    // plot the FFT
    graphHelper2->setGraphData(1,fftMagnitudeBuffer2,kBufferLength2/2,sqrt(kBufferLength2)); // set graph channel
    
    graphHelper2->update(); // update the graph
}


#pragma mark - status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}



//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

@end
