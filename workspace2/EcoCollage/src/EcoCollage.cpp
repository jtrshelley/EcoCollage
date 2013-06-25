/*
 * EcoCollage.cpp
 *
 *  Created on: June 3, 2013
 *    Author: Brianna
 */
#include <iostream>
using namespace std;
//cout << "bro" << endl;
#include <stdlib.h>
#include <stdio.h>

#include <cv.h>
#include <highgui.h>

IplImage * DetectAndDrawQuads(IplImage * img)
{
	CvSeq * contours;
	CvSeq * result;
	CvMemStorage * storage = cvCreateMemStorage(0);
	IplImage * ret = cvCreateImage(cvGetSize(img), 8, 3);
	IplImage * temp = cvCloneImage(img);
	//cvCvtColor(img, temp, CV_HSV2GRAY);

	cvFindContours(temp, storage, &contours, sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));

	while(contours)
	{
		result = cvApproxPoly(contours, sizeof(CvContour), storage, CV_POLY_APPROX_DP, cvContourPerimeter(contours) * 0.02, 0);
		if(result->total==4 && fabs(cvContourArea(result, CV_WHOLE_SEQ)) > 20)
		{
			CvPoint * pt[4];
			for(int i=0;i < 4; i++)
				pt[i] = (CvPoint * )cvGetSeqElem(result, i);

			cvLine(ret, * pt[0], * pt[1], cvScalar(255));
			cvLine(ret, * pt[1], * pt[2], cvScalar(255));
			cvLine(ret, * pt[2], * pt[3], cvScalar(255));
			cvLine(ret, * pt[3], * pt[0], cvScalar(255));
		}

		contours = contours -> h_next;
	}

	cvReleaseImage(&temp);
	cvReleaseMemStorage(&storage);

	return ret;
}

//Thresholding function
IplImage * GetThresholdedImage(IplImage * img)
{
	//Convert the image into an HSV image
	IplImage * imgHSV = cvCreateImage(cvGetSize(img), 8, 3);
	cvCvtColor(img, imgHSV, CV_BGR2HSV);

	//New image that will hold the thresholded image
	IplImage * imgThreshed = cvCreateImage(cvGetSize(img), 8, 1);

	cvInRangeS(imgHSV, cvScalar(40, 100, 100), cvScalar(80, 255, 255), imgThreshed);

	//Release the temp HSV image and return this thresholded image
	cvReleaseImage(&imgHSV);
	return imgThreshed;
}

int main()
{
	// Initialize capturing live feed from the camera
	CvCapture * capture = 0;
	capture = cvCaptureFromCAM(0);

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
		IplImage * contourDrawn = DetectAndDrawQuads(imgGreenThresh);

        // Calculate the moments to estimate the position of the ball
        CvMoments *moments = (CvMoments*)malloc(sizeof(CvMoments));
        cvMoments(imgGreenThresh, moments, 1);

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
		cvNamedWindow("contours");
		cvShowImage("contours", contourDrawn);

		//Wait 50mS
        int c = cvWaitKey(10);
        //If 'ESC' is pressed, break the loop
        if((char)c==27 ) break;
	}

	return 0;
}
