#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>
#include <time.h>
#include <fstream>
#include <opencv2/opencv.hpp>

using cv::Vec3b;

//global
int NUM_THREADS;
int radius;
char* imageName;
cv::Mat image; 
cv::Mat blur;

void *blur_image(void *threadid) {

	int rows = image.rows;
	int cols = image.cols;
	
	//always radius less than protect, minimun value = 2
	int protect = radius + 1;
	
	int init;
	int final;

	long idthread = (long)threadid;
	int pass = floor(rows/NUM_THREADS);

	if(idthread == 0) {
		//initial thread
		init = protect;
		final = pass;
	}
	else if(idthread == NUM_THREADS - 1) {
		//final thread
		init = (idthread * pass) + 1;
		final = rows - protect;
	}else {
		init = (idthread * pass) + 1;
		final = init + pass - 1;
	}


	for (int i = init; i <= final; ++i)
	{
		for (int j = protect; j < image.cols - protect; ++j)
		{

			//(i+1,j) down
			//(i-1,j) top
			//(i,j+1) right
			//(i,j-1) left

			//RED
			blur.at<Vec3b>(i,j)[0] = (image.at<Vec3b>(i+radius,j)[0] + image.at<Vec3b>(i-radius,j)[0] + image.at<Vec3b>(i,j+radius)[0] + image.at<Vec3b>(i,j-radius)[0])/4;

			//GREEN
			blur.at<Vec3b>(i,j)[1] = (image.at<Vec3b>(i+radius,j)[1] + image.at<Vec3b>(i-radius,j)[1] + image.at<Vec3b>(i,j+radius)[1] + image.at<Vec3b>(i,j-radius)[1])/4;

			//BLUE
			blur.at<Vec3b>(i,j)[2] = (image.at<Vec3b>(i+radius,j)[2] + image.at<Vec3b>(i-radius,j)[2] + image.at<Vec3b>(i,j+radius)[2] + image.at<Vec3b>(i,j-radius)[2])/4;
		}
	}
} 

int main( int argc, char* argv[] )
{
	char* imageName = argv[1];
	image = cv::imread( imageName, cv::IMREAD_COLOR );
	if( !image.data )
	{
		perror("No image data \n");
		
	}

	if (argv[2]==NULL || argc<3) {
		radius = 3;
		NUM_THREADS = 4;
		std::cout<<"Radius and NUM_THREADS are null"<<std::endl;
	}
	else {
		radius = atoi(argv[2]);
	}

	if (argv[3]==NULL || argc<4) {
		NUM_THREADS = 4;
		std::cout<<"NUM_THREADS is null"<<std::endl;
	}
	else {
		NUM_THREADS = atoi(argv[3]);
	}

	blur = image.clone();

	//take the time
	struct timespec start, finish;
    double elapsed;

    clock_gettime(CLOCK_MONOTONIC, &start);

	pthread_t threads[NUM_THREADS];
	int rc;	
	long i;

	for (i = 0; i < NUM_THREADS; ++i)
	{
		rc = pthread_create(&threads[i], NULL, blur_image, (void*) i);
		if(rc)
			perror("Error: we cannot create thread");
	}

	//this join increases runtime
	for (i = 0; i < NUM_THREADS; ++i)
		pthread_join(threads[i], NULL);

	clock_gettime(CLOCK_MONOTONIC, &finish);
    elapsed = (finish.tv_sec - start.tv_sec);
    elapsed += (finish.tv_nsec - start.tv_nsec) / 1000000000.0;
	std::cout<<"Time: "<< elapsed << std::endl;

	//write in file
	std::ofstream output;
    output.open("mainposixResult.txt", std::ofstream::app | std::ofstream::out );
    output<< imageName <<", "<< radius << ", " << NUM_THREADS <<", "<< elapsed << std::endl;
	output.close();

	cv::imwrite( "blurimage.jpg", blur );
	//cv::namedWindow( "Blur image", cv::WINDOW_AUTOSIZE );
	//cv::imshow( "Blur image", blur );

	cv::waitKey(0);

	return 0;
}
