/*
 * EcoCollage.cpp
 *
 *  Created on: June 3, 2013
 *    Author: Brianna
 */
#include <iostream>
using namespace std;
#include <stdlib.h>
#include <stdio.h>

#include <cv.h>
#include <highgui.h>

void DetectAndDrawQuads(IplImage * img)
{
	CvSeq * contours;
	CvSeq * result;
	CvMemStorage * storage = cvCreateMemStorage(0);
//	IplImage * ret = cvCreateImage(cvGetSize(img), 8, 3);
	IplImage * temp = cvCloneImage(img);

	//cvCvtColor(img, temp, CV_HSV2GRAY);
	int c = cvWaitKey(50);
	if(c == 32){
		printf("spacebar pressed\n");
		int count = 0;
		cvFindContours(temp, storage, &contours, sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
		while(contours)
		{

			result = cvApproxPoly(contours, sizeof(CvContour), storage, CV_POLY_APPROX_DP, cvContourPerimeter(contours) * 0.02, 0);
			if(result->total==4 && fabs(cvContourArea(result, CV_WHOLE_SEQ)) > 20)
			{
				count++;
				CvPoint * pt[4];
				for(int i=0;i < 4; i++)
					pt[i] = (CvPoint * )cvGetSeqElem(result, i);

				int x = pt[0]->x;
				int y = pt[0]->y;
				int w = abs(pt[2]->x - pt[0]->x);
				int h = abs(pt[2]->y - pt[0]->y);

				printf("x:  %d, y:  %d, w:  %d, h:  %d \n", x, y, w, h);

			}
			contours = contours -> h_next;
		}
	}
	cvReleaseImage(&temp);
	cvReleaseMemStorage(&storage);
}

	//Thresholding function
	IplImage * GetThresholdedImage(IplImage * img)
	{
		//Convert the image into an HSV image
		IplImage * imgHSV = cvCreateImage(cvGetSize(img), 8, 3);
		cvCvtColor(img, imgHSV, CV_BGR2HSV);

		//New image that will hold the thresholded image
		IplImage * imgThreshed = cvCreateImage(cvGetSize(img), 8, 1);

//*******************************Projector On***************************************//
//**	white
//		cvInRangeS(imgHSV, cvScalar(0, 0, 0), cvScalar(20, 55, 255), imgThreshed);
//**	white on black
//		cvInRangeS(imgHSV, cvScalar(0, 0, 200), cvScalar(360, 40, 255), imgThreshed);
//**	red
//		cvInRangeS(imgHSV, cvScalar(0, 100, 50), cvScalar(15, 200, 150), imgThreshed);
//**	orange
//		cvInRangeS(imgHSV, cvScalar(10, 100, 0), cvScalar(30, 250, 175), imgThreshed);
//**	green
//		cvInRangeS(imgHSV, cvScalar(30, 50, 50), cvScalar(90, 200, 130), imgThreshed);
//**	wood
//		cvInRangeS(imgHSV, cvScalar(10, 50, 120), cvScalar(30, 100, 165), imgThreshed);
//**	blue
//		cvInRangeS(imgHSV, cvScalar(90, 0, 40), cvScalar(150, 90, 130), imgThreshed);
//**	black
//		cvInRangeS(imgHSV, cvScalar(0, 0, 0), cvScalar(180, 190, 90), imgThreshed);


//*******************************Projector Off***************************************//
//**	black on white
//		cvInRangeS(imgHSV, cvScalar(0, 0, 0), cvScalar(20, 55, 255), imgThreshed);
//**	red
//		cvInRangeS(imgHSV, cvScalar(0, 100, 50), cvScalar(15, 255, 130), imgThreshed);
//**	orange
//		cvInRangeS(imgHSV, cvScalar(5, 100, 60), cvScalar(30, 225, 130), imgThreshed);
//**	green
//		cvInRangeS(imgHSV, cvScalar(40, 75, 50), cvScalar(90, 255, 150), imgThreshed);
//**	wood
//		cvInRangeS(imgHSV, cvScalar(15, 60, 90), cvScalar(60, 200, 200), imgThreshed);
//**	blue
//		cvInRangeS(imgHSV, cvScalar(90, 90, 20), cvScalar(150, 200, 90), imgThreshed);
//**	black
//		cvInRangeS(imgHSV, cvScalar(0, 0, 0), cvScalar(100, 200, 30), imgThreshed);
//**	silicon blue
//		cvInRangeS(imgHSV, cvScalar(90, 100, 50), cvScalar(150, 220, 120), imgThreshed);

//*************NEW******************Projector Off*********************COLORS******************//
//**	red
//		cvInRangeS(imgHSV, cvScalar(0, 60, 60), cvScalar(15, 200, 255), imgThreshed);
//**	blue
		cvInRangeS(imgHSV, cvScalar(90, 40, 50), cvScalar(150, 255, 200), imgThreshed);
//**	orange
//		cvInRangeS(imgHSV, cvScalar(0, 60, 50), cvScalar(30, 190, 150), imgThreshed);
//**	green
//		cvInRangeS(imgHSV, cvScalar(40, 75, 50), cvScalar(90, 255, 150), imgThreshed);
//**	Yellow
//		cvInRangeS(imgHSV, cvScalar(5, 40, 60), cvScalar(40, 225, 225), imgThreshed);
//**	gray
//		cvInRangeS(imgHSV, cvScalar(90, 50, 0), cvScalar(100, 255, 255), imgThreshed);


		//Release the temp HSV image and return this thresholded image
		cvReleaseImage(&imgHSV);
		return imgThreshed;
	}

	int main()
	{
		// Initialize capturing live feed from the camera
		CvCapture * capture = 0;
		capture = cvCaptureFromCAM(1);
		int currentWidth = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH);
		int currentHeight = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT);
		//cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH, currentWidth/2);
		//cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT, currentHeight/2-100);

		// Couldn't get a device? Throw an error and quit
		if(!capture)
		{
			printf("Could not initialize capturing...\n");
			return -1;
		}
		while(true)
		{
			// Will hold a frame captured from the camera
			IplImage * frame = 0;
			frame = cvQueryFrame(capture);

			//If we couldn't grab a frame... quit
			if(!frame)
				break;

			//Holds the yellow thresholded image (yellow = white, rest = black)
			IplImage * imgGreenThresh = GetThresholdedImage(frame);
			DetectAndDrawQuads(imgGreenThresh);

			// Calculate the moments to estimate the position of the ball
			CvMoments *moments = (CvMoments*)malloc(sizeof(CvMoments));
			cvMoments(imgGreenThresh, moments, 1);

//			int x = cvInRangeS;
//			switch (x)
//			{
//			case 1:
//				cvInRangeS(imgHSV, cvScalar(0, 60, 60), cvScalar(15, 200, 255), imgThreshed);
//				cout << "Red =" x;
//
//			case 2:
//				cvInRangeS(imgHSV, cvScalar(90, 40, 50), cvScalar(150, 255, 200), imgThreshed);
//
//			case 3:
//			case 4:
//			case 5:
//			case 6:
//			}

			int x = cvWaitKey(10);
			if((char)x ==99)
			{

				// The actual moment values
				double moment10 = cvGetSpatialMoment(moments, 1, 0);
				double moment01 = cvGetSpatialMoment(moments, 0, 1);
				double area = cvGetCentralMoment(moments, 0, 0);

				// Holding the last and current ball positions
				static int posX = 0;
				static int posY = 0;

				posX = moment10/area;
				posY = moment01/area;
				// Print it out for debugging purposes
				printf("position (%d,%d)\n", posX, posY);

			}

			cvNamedWindow("original");
			cvShowImage("original", frame);
			cvNamedWindow("threshold");
			cvShowImage("threshold", imgGreenThresh);


			//Wait 50mS
			int c = cvWaitKey(10);
			//If 'ESC' is pressed, break the loop
			if((char)c==27 ) break;
		}

		return 0;
	}
