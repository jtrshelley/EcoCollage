#include <iostream>
#include <cv.h>
#include <cvaux.h>
#include <highgui.h>
using namespace std;

// Define the IplImage pointers we're going to use as globals
IplImage* pFrame;
IplImage* pProcessedFrame;
IplImage* tempFrame;

// Slider for the low threshold value of our edge detection
int maxLowThreshold = 1024;
int lowSliderPosition = 150;

// Slider for the high threshold value of our edge detection
int maxHighThreshold = 1024;
int highSliderPosition = 250;

// Function to find the edges of a given IplImage object
IplImage* findEdges(IplImage* sourceFrame, double thelowThreshold, double theHighThreshold, double theAperture)
{
	// Convert source frame to greyscale version (tempFrame has already been initialised to use greyscale colour settings)
	cvCvtColor(sourceFrame, tempFrame, CV_RGB2GRAY);

	// Perform canny edge finding on tempframe, and push the result back into itself!
	cvCanny(tempFrame, tempFrame, thelowThreshold, theHighThreshold, theAperture);

	// Pass back our now processed frame!
	return tempFrame;
}

// Callback function to adjust the low threshold on slider movement
void onLowThresholdSlide(int theSliderValue)
{
	lowSliderPosition = theSliderValue;
}

// Callback function to adjust the high threshold on slider movement
void onHighThresholdSlide(int theSliderValue)
{
	highSliderPosition = theSliderValue;
}

int main(int argc, char** argv)
{
	// Create two windows
	cvNamedWindow("WebCam", CV_WINDOW_AUTOSIZE);
	cvNamedWindow("Processed WebCam", CV_WINDOW_AUTOSIZE);

	// Create the low threshold slider
	// Format: Slider name, window name, reference to variable for slider, max value of slider, callback function
	cvCreateTrackbar("Low Threshold", "Processed WebCam", &lowSliderPosition, maxLowThreshold, onLowThresholdSlide);

	// Create the high threshold slider
	cvCreateTrackbar("High Threshold", "Processed WebCam", &highSliderPosition, maxHighThreshold, onHighThresholdSlide);

	// Create CvCapture object to grab data from the webcam
	CvCapture* pCapture;

	// Start capturing data from the webcam
	pCapture = cvCaptureFromCAM(CV_CAP_V4L2);

	// Display image properties
	cout << "Width of frame: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_FRAME_WIDTH) << endl; 		// Width of the frames in the video stream
	cout << "Height of frame: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_FRAME_HEIGHT) << endl; 	// Height of the frames in the video stream
	cout << "Image brightness: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_BRIGHTNESS) << endl; 	// Brightness of the image (only for cameras)
	cout << "Image contrast: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_CONTRAST) << endl; 		// Contrast of the image (only for cameras)
	cout << "Image saturation: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_SATURATION) << endl;		// Saturation of the image (only for cameras)
	cout << "Image hue: " << cvGetCaptureProperty(pCapture, CV_CAP_PROP_HUE) << endl;			// Hue of the image (only for cameras)

	// Create an image from the frame capture
	pFrame = cvQueryFrame(pCapture);

	// Create a greyscale image which is the size of our captured image
	pProcessedFrame = cvCreateImage(cvSize(pFrame->width, pFrame->height), IPL_DEPTH_8U, 1);

	// Create a frame to use as our temporary copy of the current frame but in grayscale mode
	tempFrame = cvCreateImage(cvSize(pFrame->width, pFrame->height), IPL_DEPTH_8U, 1);

	// Loop controling vars
	char keypress;
	bool quit = false;

	while (quit == false)
	{
		// Make an image from the raw capture data
		// Note: cvQueryFrame is a combination of cvGrabFrame and cvRetrieveFrame
		pFrame = cvQueryFrame(pCapture);

		// Draw the original frame in our window
		cvShowImage("WebCam", pFrame);

		// Process the grame to find the edges
		pProcessedFrame = findEdges(pFrame, lowSliderPosition, highSliderPosition, 3);

		// Showed the processed output in our other window
		cvShowImage("Processed WebCam", pProcessedFrame);

		// Wait 20 milliseconds
		keypress = cvWaitKey(20);

		// Set the flag to quit if escape was pressed
		if (keypress == 27)
		{
			quit = true;
		}

	} // End of while loop

	// Release our stream capture object to free up any resources it has been using and release any file/device handles
	cvReleaseCapture(&pCapture);

	// Release our images
	cvReleaseImage(&pFrame);
	cvReleaseImage(&pProcessedFrame);
	// This causes errors if you don't set it to NULL before releasing it. Maybe because we assign
	// it to pProcessedFrame as the end result of the findEdges function, and we've already released pProcessedFrame!!
	tempFrame = NULL;
	cvReleaseImage(&tempFrame);

	// Destory all windows
	cvDestroyAllWindows();
}
