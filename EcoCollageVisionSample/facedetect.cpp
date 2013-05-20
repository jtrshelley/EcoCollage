// OpenCV Sample Application: facedetect.c

// Include header files
#include "cv.h"
#include "highgui.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <time.h>
#include <ctype.h>

// Create memory for calculations
static CvMemStorage* storage = 0;

// Create a new Haar classifier
static CvHaarClassifierCascade* cascade = 0;

// Function prototype for detecting and drawing an object from an image
void detect_and_draw( IplImage* image, bool record );

// Create a string that contains the cascade name
const char* cascade_name =
    "haarcascade.xml";
/*    "haarcascade_profileface.xml";*/

//File for output
FILE * outputRecord;
//these four arrays hold the last four sets of detected points for output
int prevPoint[100][2];
int prevPoint2[100][2];
int prevPoint3[100][2];
int prevPoint4[100][2];
int prevIndex = 0;
int prevIndex2 = 0;
int prevIndex3 = 0;
int prevIndex4 = 0;

//these four arrays hold the last four sets of detected points (floats)
CvPoint lastPoints[100][2];
CvPoint lastPoints2[100][2];
CvPoint lastPoints3[100][2];
CvPoint lastPoints4[100][2];
// Main function, defines the entry point for the program.
int main( int argc, char** argv )
{

    // Structure for getting video from camera or avi
    CvCapture* capture = 0;

    // Images to capture the frame from video or camera or from file
    IplImage *frame, *frame_copy = 0;
    int key = 0;

    //Removed the following lines because we're always using the same cascade.

    // Used for calculations
    //int optlen = strlen("--cascade=");

    // Input file name for avi or image file.
    //const char* input_name;

   
    // Check for the correct usage of the command line
    /*if( argc > 1 && strncmp( argv[1], "--cascade=", optlen ) == 0 )
    {
        cascade_name = argv[1] + optlen;
        input_name = argc > 2 ? argv[2] : 0;
    }
    else
    {
        fprintf( stderr,
        "Usage: facedetect --cascade=\"<cascade_path>\" [filename|camera_index]\n" );
        return -1;
        input_name = argc > 1 ? argv[1] : 0;*/
    //}


    // Load the HaarClassifierCascade
    cascade = (CvHaarClassifierCascade*)cvLoad( cascade_name, 0, 0, 0 );

    // Check whether the cascade has loaded successfully. Else report and error and quit
    if( !cascade )
    {
        fprintf( stderr, "ERROR: Could not load classifier cascade\n" );
        return -1;
    }

    // Allocate the memory storage
    storage = cvCreateMemStorage(0);

    // Find whether to detect the object from file or from camera.
    //if( !input_name || (isdigit(input_name[0]) && input_name[1] == '\0') )
    capture = cvCaptureFromCAM(0);
    cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH, 1280);
    cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT, 800);
    // else
    //    capture = cvCaptureFromAVI( input_name );

    // Create a new named window with title: result
    cvNamedWindow( "result", 1 );

    // Find if the capture is loaded successfully or not.

    // If loaded succesfully, then:
    if( capture )
    {
        // Capture from the camera.
        for(;;)
        {
            // Capture the frame and load it in IplImage
            if( !cvGrabFrame( capture ))
                break;
            frame = cvRetrieveFrame( capture );

            // If the frame does not exist, quit the loop
            if( !frame )
                break;

            // Allocate framecopy as the same size of the frame
            if( !frame_copy )
                frame_copy = cvCreateImage( cvSize(frame->width,frame->height),
                                            IPL_DEPTH_8U, frame->nChannels );

            // Check the origin of image. If top left, copy the image frame to frame_copy.
            if( frame->origin == IPL_ORIGIN_TL )
                cvCopy( frame, frame_copy, 0 );
            // Else flip and copy the image
            else
                cvFlip( frame, frame_copy, 0 );

            // Call the function to detect and draw the face
            // Wait for a while before proceeding to the next frame

            if( (key = cvWaitKey(100)) >= 0 ){
                if(key == ('d' | 'D')){
                 //printf("D key received.");
                 detect_and_draw(frame_copy, true);
                }
                if(key == ('x' | 'X')) break;
            } else {
                        detect_and_draw( frame_copy , false);
                        }

        }

        // Release the images, and capture memory
        cvReleaseImage( &frame_copy );
        cvReleaseCapture( &capture );
    }

    // If the capture is not loaded succesfully, then:
    else
    {
       printf("Capture did not load successfully.");
    }
    // Destroy the window previously created with filename: "result"
    cvDestroyWindow("result");

    // return 0 to indicate successfull execution of the program
    return 0;
}

// Function to detect and draw any faces that is present in an image
void detect_and_draw( IplImage* img , bool record )
{
    //if(record) printf("Record is TRUE this loop");
    int scale = 1;

    // Create a new image based on the input image
    IplImage* temp = cvCreateImage( cvSize(img->width/scale,img->height/scale), 8, 3 );

    // Create two points to represent the face locations
    CvPoint pt1, pt2;

    int i;
    // Clear the memory storage which was used before
    cvClearMemStorage( storage );
    // Find whether the cascade is loaded, to find the faces. If yes, then:
    if( cascade )
    {
        // There can be more than one icon in an image. So create a growable sequence of icons.
        // Detect the objects and store them in the sequence
        CvSeq* boxes = cvHaarDetectObjects( img, cascade, storage,
                                            1.1, 2, CV_HAAR_DO_CANNY_PRUNING,
                                            cvSize(40, 40) );

        // Loop the number of faces found.
        CvPoint thesePoints[boxes->total][2];
        int pointValues [boxes->total][2];

        for( i = 0; i < (boxes ? boxes->total : 0); i++ )
        {
           // Create a new rectangle for drawing the face
            CvRect* r = (CvRect*)cvGetSeqElem( boxes, i );

            // Find the dimensions of the face,and scale it if necessary
            pt1.x = r->x*scale;
            pt2.x = (r->x+r->width)*scale;
            pt1.y = r->y*scale;
            pt2.y = (r->y+r->height)*scale;
            //printf("Drawing box %d of %d \n", i, boxes->total);
            // Draw the rectangle in the input image
            cvRectangle( img, pt1, pt2, CV_RGB(255,0,0), 3, 8, 0 );
            thesePoints[i][0] = pt1;
            thesePoints[i][1] = pt2;
            pointValues[i][0] = ((pt2.x - pt1.x)/2) + pt1.x;
            pointValues[i][1] = ((pt2.y - pt1.y)/2) + pt1.y;

        }
        //int pointValues2[boxes->total][2];
        int index = 0;
        
        //commented out code here is for checking whether or not there was a box drawn at that point on the previous round
       // bool check = false;
        if(prevIndex != 0){
            for(int j = 0; j < prevIndex; j++){
 //               for( int k = 0; k < boxes->total; k++){
 //                   if((pointValues[k][0] - 50 <= prevPoint[j][0]) && (prevPoint[j][0]<= pointValues[k][0]+ 50)){
 //                     if((pointValues[k][1] - 50 <= prevPoint[j][1]) && (prevPoint[j][1]<= pointValues[k][1]+ 50)){
 //                        check = true;
 //                        //printf("Point matched previous point: %d, %d", j, k);
  //                    }
  //                  }
  //              }
  //              if(!check){
                    cvRectangle(img, lastPoints[j][0], lastPoints[j][1], CV_RGB(255, 0, 0), 3, 8, 0);
                    cvRectangle(img, lastPoints2[j][0], lastPoints2[j][1], CV_RGB(255, 0, 0), 3, 8, 0);
                    cvRectangle(img, lastPoints3[j][0], lastPoints3[j][1], CV_RGB(255, 0, 0), 3, 8, 0);
                    //cvRectangle(img, lastPoints4[j][0], lastPoints4[j][1], CV_RGB(255, 0, 0), 3, 8, 0);
                    //pointValues2[index][0] = prevPoint[j][0];
                    //pointValues2[index][1] = prevPoint[j][1];
                    index++;
   //             }
   //             check = false;
          }
        }
        CvFont font;
        cvInitFont(&font, CV_FONT_VECTOR0, 0.5, 0.5, 0.0, 1.0 );
        
        
        //all of the following code first writes the points out to the screen, and then writes the points to the outputRecord for use by NetLogo
        if(record == true) {
                outputRecord = fopen("results.txt", "w+");
                if(outputRecord == NULL){
                    printf("Error when opening output file. Exitting.");
                exit(EXIT_FAILURE);
                }
                float xStart = 348.0;
                float yStart = 29.0;
                float xMax = 578.0;
                float yMax = 715.0;
            
            
            for(i = 0; i < boxes->total; i++){
                printf("%f , %f \n",  (float)(pointValues[i][0] - xStart) * ((float)21/xMax)-.2, ((float)pointValues[i][1] - yStart )*((float)26/yMax) );
                fprintf(outputRecord, "%f %f \n", ((float)(pointValues[i][0] - xStart) * ((float)21/xMax))-.2, (((float)pointValues[i][1] - yStart )* ((float)26/yMax)));
                if(i < index){
                    printf("%f , %f \n",  ((float)(prevPoint[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint[i][1] - yStart)* ((float)26/yMax)) );
                    fprintf(outputRecord, "%f %f \n", ((float)(prevPoint[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint[i][1] - yStart )* ((float)26/yMax)));
                }
                if(i < prevIndex){
                    printf("%f , %f \n",  ((float)(prevPoint2[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint2[i][1] - yStart)* ((float)26/yMax)) );
                    fprintf(outputRecord, "%f %f \n", ((float)(prevPoint2[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint2[i][1] - yStart )* ((float)26/yMax)));
                }
                if(i < prevIndex2){
                    printf("%f , %f \n",  ((float)(prevPoint3[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint3[i][1] - yStart)* ((float)26/yMax)) );
                    fprintf(outputRecord, "%f %f \n", ((float)(prevPoint3[i][0] - xStart) * ((float)21/xMax))-.2, (((float)prevPoint3[i][1] - yStart )* ((float)26/yMax)));
                }
                if(i < prevIndex3){
                    //printf("%f , %f \n",  ((float)(prevPoint4[i][0] - xStart) * ((float)21/xMax)), (((float)prevPoint4[i][1] - yStart)* ((float)26/yMax)) );
                    //fprintf(outputRecord, "%f %f \n", ((float)(prevPoint4[i][0] - xStart) * ((float)21/xMax)), (((float)prevPoint4[i][1] - yStart )* ((float)26/yMax)));
                }
            }
            fclose(outputRecord);
            cvPutText(img, "Sent to File", cvPoint(15,25), &font, cvScalar(255, 255, 255, 0));

        }
        //Not sure why 'D' was chosen for sending - definitely want to think about this a little
        cvPutText(img, "Press D when ready to send to file." , cvPoint(15, 25), &font, cvScalar(255, 255, 255, 0));
        for(int h = 0; h < boxes->total; h++){
            if(h < prevIndex3){
            prevPoint4[h][0] = prevPoint4[h][0];
            prevPoint4[h][1] = prevPoint4[h][1];
            lastPoints4[h][0] = lastPoints4[h][0];
            lastPoints4[h][1] = lastPoints4[h][1];
            }
            if(h < prevIndex2){
            prevPoint3[h][0] = prevPoint2[h][0];
            prevPoint3[h][1] = prevPoint2[h][1];
            lastPoints3[h][0] = lastPoints2[h][0];
            lastPoints3[h][1] = lastPoints2[h][1];
            }
            if(h < prevIndex){
            prevPoint2[h][0] = prevPoint[h][0];
            prevPoint2[h][1] = prevPoint[h][1];
            lastPoints2[h][0] = lastPoints[h][0];
            lastPoints2[h][1] = lastPoints[h][1];
            }
            prevPoint[h][0] = pointValues[h][0];
            prevPoint[h][1] = pointValues[h][1];
            lastPoints[h][0] = thesePoints[h][0];
            lastPoints[h][1] = thesePoints[h][1];
        }
        prevIndex4 = prevIndex3;
        prevIndex3 = prevIndex2;
        prevIndex2 = prevIndex;
        prevIndex = boxes->total;
    }
    // Show the image in the window named "result"
    cvShowImage( "result", img );

    // Release the temp image created.
    cvReleaseImage( &temp );
}
