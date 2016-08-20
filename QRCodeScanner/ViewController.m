//
//  ViewController.m
//  QRCodeScanner
//
//  Created by Avinash Kashyap on 8/20/16.
//  Copyright © 2016 Headerlabs. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //set button corner radious and border color
    self.scanButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.scanButton.layer.borderWidth = 0.7;
    self.scanButton.layer.cornerRadius = 3;
    self.scanButton.clipsToBounds = YES;
    //setting lable color and border
    self.statusLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.statusLabel.layer.borderWidth = 0.7;
    self.statusLabel.layer.cornerRadius = 2;
    self.statusLabel.clipsToBounds = YES;
    
    //setting preview view border and corner radius
    self.previewView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.previewView.layer.borderWidth = 0.5;
    self.previewView.layer.cornerRadius = 5;
    self.previewView.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL) startReading{
    
    NSError *error;
    
    //For Front Camera
    //    AVCaptureDevice *captureDevice = [AVCaptureDevice deviceWithUniqueID:@"com.apple.avfoundation.avcapturedevice.built-in_video:1"];
    
    //For Default Camera
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //add capture device input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"Error = %@", error.localizedDescription);
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        [[[UIAlertView alloc] initWithTitle:@"Camera Unavailable" message:[NSString stringWithFormat:@"The %@ has not been given a permission to your camera. Please check the Privacy Settings: Settings -> %@ -> Privacy -> Camera", appName, appName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return NO;
    }
    //initialize session
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    //configure meta data output
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    //Add Preview layer
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.videoPreviewLayer.frame = self.previewView.bounds;
    [self.previewView.layer addSublayer:self.videoPreviewLayer];
    
    //start session
    [self.captureSession startRunning];
    return YES;
}
//Stop Reading Code
-(void) stopReading{
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

#pragma mark -
//AVCaptureMetadataOutputObjectsDelegate Delegate method
-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if (metadataObjects != nil && [metadataObjects count]>0) {
        id metadataObj= [metadataObjects objectAtIndex:0];
        if ([metadataObj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {

            AVMetadataMachineReadableCodeObject *barCodeObject;
            barCodeObject = (AVMetadataMachineReadableCodeObject *)[self.videoPreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadataObj];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"metadata readable object count = %d   \n Meta Data = %@",(int)metadataObjects.count,metadataObjects);

                self.statusLabel.hidden = NO;
                [self.statusLabel performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
                [self stopReading];
                [self.scanButton setTitle:@"Scan" forState:UIControlStateNormal];
                self.scanButton.enabled = YES;
            });// end dispatch queue main thread
        }//end readable code object if block
    }//end if block meta data count check
}
//Start and Stop button Actio
-(IBAction)clickButtonAction:(id)sender{
    
    if ([self.captureSession isRunning] == YES) {
        self.statusLabel.hidden = YES;
        self.statusLabel.text = @"";
        [self stopReading];
        [self.scanButton setTitle:@"Scan" forState:UIControlStateNormal];
    }
    else{
        if ([self startReading]) {
            self.statusLabel.hidden = NO;
            self.statusLabel.text = @"Scanning...";
            [self startReading];
            [self.scanButton setTitle:@"Stop" forState:UIControlStateNormal];
        }
        
    }
}

@end
