/*
 * main.cpp
 *
 *  Created on: Jun 18, 2013
 *      Author: brianna
 */

#include "main.h"
#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include <stdlib.h>
#include <stdio.h>
#include "opencv/highgui.h"
#include "opencv/cv.h"
#include "opencv2/nonfree/features2d.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace cv;

int main()
{
	Mat object = imread( "photo1.jpg", CV_LOAD_IMAGE_GRAYSCALE );

	if( !object.data )
	{
		std::cout<< "Error reading object " << std::endl;
		return -1;
	}

	//Detect the keypoints using SURF Detector
	int minHessian = 500;

	SurfFeatureDetector detector(minHessian);
	std::vector<KeyPoint> kp_object;

	detector.detect( object, kp_object );

	//Calculate descriptors (feature vectors)
	SurfDescriptorExtractor extractor;
	Mat des_object;

	extractor.compute( object, kp_object, des_object );
	printf("Number of descriptors found for initial object: %d", kp_object.size());

	FlannBasedMatcher matcher;

	VideoCapture cap(0);
	cap.set(CV_CAP_PROP_FRAME_WIDTH, 1280);
	cap.set(CV_CAP_PROP_FRAME_HEIGHT, 1024);

	namedWindow("Good Matches");

	std::vector<Point2f> obj_corners(4);

	//Get the corners from the object
	obj_corners[0] = cvPoint(0,0);
	obj_corners[1] = cvPoint( object.cols, 0 );
	obj_corners[2] = cvPoint( object.cols, object.rows );
	obj_corners[3] = cvPoint( 0, object.rows );

	char key = 'a';
	int framecount = 0;
	Mat frozenframe[5];

	int state = 1;
	while (key != 27)
	{
		Mat frame;
		cap >> frame;

		//first five frames are preserved so that we can use them once
		//we get past them
		if (framecount < 5)
		{
			frozenframe[4] = frame.clone();
			framecount++;
			continue;
		}

		if(state % 2 == 0){
			frame = frozenframe[4].clone();
		}

		Mat des_image, img_matches;
		std::vector<KeyPoint> kp_image;
		std::vector<vector<DMatch > > matches;
		std::vector<DMatch > good_matches;
		std::vector<Point2f> obj;
		std::vector<Point2f> scene;
		std::vector<Point2f> scene_corners(4);
		Mat H;
		Mat image;


		cvtColor(frame, image, CV_RGB2GRAY);


		if(state %2  == 0){
			for(int i = 0; i < 5 ; i++){
				cvtColor(frozenframe[i], image, CV_RGB2GRAY);
				detector.detect( image, kp_image );
				extractor.compute( image, kp_image, des_image );

				matcher.knnMatch(des_object, des_image, matches, 2);
				for(int j = 0; j < min(des_image.rows-1,(int) matches.size()); j++) //THIS LOOP IS SENSITIVE TO SEGFAULTS
				{
					if((matches[j][0].distance < 0.6*(matches[j][1].distance)) && ((int) matches[j].size()<=2 && (int) matches[j].size()>0))
					{
						good_matches.push_back(matches[j][0]);
						printf("Outer loop is on: %d, Number of matches is: %d\n", i, good_matches.size());
					}
				}
			}
			//Draw only "good" matches
			drawMatches( object, kp_object, image, kp_image, good_matches, img_matches, Scalar::all(-1), Scalar::all(-1), vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );

			if (good_matches.size() >= 4)
			{
				for( int i = 0; i < good_matches.size(); i++ )
				{
					//Get the keypoints from the good matches
					obj.push_back( kp_object[ good_matches[i].queryIdx ].pt );
					scene.push_back( kp_image[ good_matches[i].trainIdx ].pt );
				}

				H = findHomography( obj, scene, CV_RANSAC );

				perspectiveTransform( obj_corners, scene_corners, H);

				//Draw lines between the corners (the mapped object in the scene image )
				line( img_matches, scene_corners[0] + Point2f( object.cols, 0), scene_corners[1] + Point2f( object.cols, 0), Scalar(0, 255, 0), 4 );
				line( img_matches, scene_corners[1] + Point2f( object.cols, 0), scene_corners[2] + Point2f( object.cols, 0), Scalar( 0, 255, 0), 4 );
				line( img_matches, scene_corners[2] + Point2f( object.cols, 0), scene_corners[3] + Point2f( object.cols, 0), Scalar( 0, 255, 0), 4 );
				line( img_matches, scene_corners[3] + Point2f( object.cols, 0), scene_corners[0] + Point2f( object.cols, 0), Scalar( 0, 255, 0), 4 );
			}
			imshow( "Good Matches", img_matches );
		}
		//Show detected matches
		imshow( "Capture", frame );


		key = waitKey(1);
		//Wait 50mS
		int c = cvWaitKey(10);
		//this populates the array of frozenframes such that we can keep track of the last
		//five frames that we saw. adds the newest frame to the last index, after moving the other
		//ones up
		frozenframe[0] = frozenframe[1].clone();
		frozenframe[1] = frozenframe[2].clone();
		frozenframe[2] = frozenframe[3].clone();
		frozenframe[3] = frozenframe[4].clone();
		frozenframe[4] = frame.clone();
		//If 'ESC' is pressed, break the loop
		if ((char) c==99){
			state++;
		}
		if((char)c==27 ) break;
	}
	return 0;
}
