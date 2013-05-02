//
//  main.m
//  CICommandLineFaceDetector
//
//  Created by Alexander Kachkaev on 02/05/2013.
//  Copyright (c) 2013 Alexander Kachkaev. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AppKit/NSImage.h>

#define OK       0
#define NO_INPUT 1
#define TOO_LONG 2

// Reads one line from stdin
// http://stackoverflow.com/questions/4023895/how-to-read-string-entered-by-user-in-c
static int getLine (char *prmpt, char *buff, size_t sz) {
    int ch, extra;
    
    // Get line with buffer overrun protection.
    if (prmpt != NULL) {
        printf ("%s", prmpt);
        fflush (stdout);
    }
    if (fgets (buff, (int)sz, stdin) == NULL)
        return NO_INPUT;
    
    // If it was too long, there'll be no newline. In that case, we flush
    // to end of line so that excess doesn't affect the next call.
    if (buff[strlen(buff)-1] != '\n') {
        extra = 0;
        while (((ch = getchar()) != '\n') && (ch != EOF))
            extra = 1;
        return (extra == 1) ? TOO_LONG : OK;
    }
    
    // Otherwise remove newline and give string back to caller.
    buff[strlen(buff)-1] = '\0';
    return OK;
}


int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        bool lowAccuracy = false;
        
        // Look for --low-accuracy in the app arguments
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        for (int i = 1; i < [args count]; ++i){
            if ([[args objectAtIndex:i] isEqualToString:@"--low-accuracy"]) {
                lowAccuracy = true;
            } else {
                printf("Unknown argument %s, only --low-accuracy is permitted\n", [[args objectAtIndex:i] UTF8String]);
                return 1;
            }
        }
       
        // Init the file manager, the face detector and other variables
        NSFileManager *fileManager = [NSFileManager defaultManager];
        CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObjectsAndKeys:(lowAccuracy ? CIDetectorAccuracyLow : CIDetectorAccuracyHigh), CIDetectorAccuracy, nil]];
        NSDictionary  *opts = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], CIDetectorImageOrientation, nil];
        
        NSString *imagePath;
        NSArray *faces;
        int rc;
        char buff[300];
        float imageHeight;

        // Main loop
        while (true) {
            
            // Prompt image path
            rc = getLine ("Enter image path> ", buff, sizeof(buff));
            
            // Exit if an empty string is given or if it's too long
            if (rc == NO_INPUT || strlen(buff) == 0) {
                break;
            }
            if (rc == TOO_LONG) {
                printf ("Error: path too long\n");
                continue;
            }
            
            // Check image path validity
            imagePath = [NSString stringWithFormat:@"%s", buff];
            if (![fileManager fileExistsAtPath:imagePath]){
                printf("Error: file does not exist\n");
                continue;
            }

            // Get the image
            NSURL *fileURL = [NSURL fileURLWithPath:imagePath];
            CIImage *image = [CIImage imageWithContentsOfURL:fileURL];

            // Handle invalid images
            if (image == NULL) {
                printf ("Error: wrong image\n");
                continue;
            }
            
            // Extract image height to flip the y coordinates of the faces later on
            imageHeight = [[[image properties] valueForKey:@"PixelHeight"] floatValue];

            // Detect faces
            faces = [faceDetector featuresInImage:image options: opts];

            // Generate the output
            NSMutableString* facesOutput = [NSMutableString string];
            
            for (CIFaceFeature *face in faces) {
                CGRect bounds = face.bounds;
                [facesOutput appendFormat:@",[%.0f,%.0f,%.0f,%.0f]", bounds.origin.x, imageHeight - bounds.origin.y - bounds.size.height, bounds.size.width, bounds.size.height];
            }
            if ([faces count] > 0) {
                [facesOutput deleteCharactersInRange:NSMakeRange(0, 1)];
            }
            
            // Return the output
            printf("[%s]\n", [facesOutput UTF8String]);
        }
    }
    return 0;
}

