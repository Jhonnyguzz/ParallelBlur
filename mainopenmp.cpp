#include <iostream>
#include <time.h>
#include <opencv2/opencv.hpp>
#include <fstream>
#include "omp.h"

using namespace cv;

int main( int argc, char** argv )
{
	char* imageName = argv[1];
	Mat image;
	image = imread( imageName, IMREAD_COLOR );
	if( !image.data )
	{
		printf( " No image data \n " );
		return -1;
	}

	Mat blur = image.clone();
	
	int radius;
	int NUM_THREADS;

	if(argv[2]==NULL || argc<3) {
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

	int protect = radius + 1;
	//always radius less than protect, minimun value = 2

	//take the time
	struct timespec start, finish;
    double elapsed;

    clock_gettime(CLOCK_MONOTONIC, &start);
    double start_omp_time = omp_get_wtime();

	omp_set_num_threads(NUM_THREADS);

	#pragma omp parallel for
	for (int i = protect; i < image.rows - protect; ++i)
	{
		for (int j = protect; j < image.cols - protect; ++j)
		{

			//(i+1,j) right
			//(i-1,j) left
			//(i,j+1) down
			//(i,j-1) top

			//RED
			blur.at<Vec3b>(i,j)[0] = (image.at<Vec3b>(i+radius,j)[0] + image.at<Vec3b>(i-radius,j)[0] + image.at<Vec3b>(i,j+radius)[0] + image.at<Vec3b>(i,j-radius)[0])/4;

			//GREEN
			blur.at<Vec3b>(i,j)[1] = (image.at<Vec3b>(i+radius,j)[1] + image.at<Vec3b>(i-radius,j)[1] + image.at<Vec3b>(i,j+radius)[1] + image.at<Vec3b>(i,j-radius)[1])/4;

			//BLUE
			blur.at<Vec3b>(i,j)[2] = (image.at<Vec3b>(i+radius,j)[2] + image.at<Vec3b>(i-radius,j)[2] + image.at<Vec3b>(i,j+radius)[2] + image.at<Vec3b>(i,j-radius)[2])/4;

		}
	}

	clock_gettime(CLOCK_MONOTONIC, &finish);
    elapsed = (finish.tv_sec - start.tv_sec);
    elapsed += (finish.tv_nsec - start.tv_nsec) / 1000000000.0;
	std::cout<<"Time: "<< elapsed << std::endl;
	std::cout<<"Omp Time: "<< omp_get_wtime() - start_omp_time << std::endl;

	//write in file
	std::ofstream output;
    output.open("mainopenmpResult.txt", std::ofstream::app | std::ofstream::out );
    output<< imageName <<", "<< radius << ", " << NUM_THREADS <<", "<< elapsed << std::endl;
	output.close();

	imwrite( "blurimage.jpg", blur );
	//namedWindow( "Blur image", WINDOW_AUTOSIZE );
	//imshow( "Blur image", blur );
	waitKey(0);

	return 0;
}
