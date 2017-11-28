#include <iostream>
#include <stdlib.h>
#include <time.h>
#include <fstream>
#include <cuda_runtime.h>
#include <opencv2/opencv.hpp>

using namespace cv;


__global__ void blurEffect(int *R, int *G, int *B, int *RED, int *GREEN, int *BLUE, int size, int rows, int cols, int kernel, int NTHREADS)
{
  int id = blockDim.x * blockIdx.x + threadIdx.x;

  //using just for "for loop"
  //int start = id*size/NTHREADS;
  //int end = (id+1)*size/NTHREADS;

  int tmp_red = 0;
  int tmp_green = 0;
  int tmp_blue = 0;

  /*
  for (int i = start; i < end; ++i)
  {
    tmp_red = 0;
    tmp_green = 0;
    tmp_blue = 0;

    if ( (i-cols)>0 ) {
      tmp_red += R[i-cols*kernel];
      tmp_green += G[i-cols*kernel];
      tmp_blue += B[i-cols*kernel];
    }

    if ( (i+cols)<size ) {
      tmp_red += R[i+cols*kernel];
      tmp_green += G[i+cols*kernel];
      tmp_blue += B[i+cols*kernel];
    }

    if ( i%cols == 0 ) {
      tmp_red += R[i+kernel];
      tmp_green += G[i+kernel];
      tmp_blue += B[i+kernel];
    }
    else if ( i%cols == cols-1 ) {
      tmp_red += R[i-kernel];
      tmp_green += G[i-kernel];
      tmp_blue += B[i-kernel];
    }
    else {
      tmp_red += R[i+kernel] + R[i-kernel];
      tmp_green += G[i+kernel] + G[i-kernel];
      tmp_blue += B[i+kernel]+ B[i-kernel];
    }

    RED[i] = tmp_red/4;
    GREEN[i] = tmp_green/4;
    BLUE[i] = tmp_blue/4;
  }*/

  if (id < size)
  {
    tmp_red = 0;
    tmp_green = 0;
    tmp_blue = 0;

    if ( (id-cols*kernel) > 0 ) {
      tmp_red += R[id-cols*kernel];
      tmp_green += G[id-cols*kernel];
      tmp_blue += B[id-cols*kernel];
    }

    if ( (id+cols*kernel) < size ) {
      tmp_red += R[id+cols*kernel];
      tmp_green += G[id+cols*kernel];
      tmp_blue += B[id+cols*kernel];
    }

    if ( id%cols == 0 ) {
      tmp_red += R[id+kernel];
      tmp_green += G[id+kernel];
      tmp_blue += B[id+kernel];
    }
    else if ( id%cols == cols-1 ) {
      tmp_red += R[id-kernel];
      tmp_green += G[id-kernel];
      tmp_blue += B[id-kernel];
    }
    else {
      tmp_red += R[id+kernel] + R[id-kernel];
      tmp_green += G[id+kernel] + G[id-kernel];
      tmp_blue += B[id+kernel]+ B[id-kernel];
    }

    RED[id] = tmp_red/4;
    GREEN[id] = tmp_green/4;
    BLUE[id] = tmp_blue/4;
  }

}

void randomFill(int *V, int row, int col){
  for(int i=0 ; i<row ; i++){
    for(int j=0 ; j<col ; j++){
      V[i*col+j] = 0;
    }
  }
}

void checkError(string s,cudaError_t err){
	if(err != cudaSuccess){
		std::cout<<s<<" "<<cudaGetErrorString(err)<<std::endl;
		exit(EXIT_FAILURE);
	}
}

int main( int argc, char** argv )
{
  char* imageName = argv[1];
  Mat image;
  image = imread( imageName, IMREAD_COLOR );
  if( !image.data )
  {
    std::cout<<" No image data \n ";
    return -1;
  }

  Mat blur = image.clone();

  int radius;
  size_t the_size = image.rows * image.cols * sizeof(int);
  int total_size = image.rows * image.cols;

  //TODO using for "for loop" inside __global__ function
  //int BLOCKS = 2;
  int NTHREADS = 192;
  int threadsPerBlock = 256;

  if(argv[2]==NULL || argc<3) {
    radius = 3;
    NTHREADS = 192;
    threadsPerBlock = 256;
    std::cout<<"Radius and CUDA NUM_THREADS are null"<<std::endl;
  }
  else {
    radius = atoi(argv[2]);
  }

	if (argv[3]==NULL || argc<4) {
		NTHREADS = 192;
    threadsPerBlock = 256;
		std::cout<<"CUDA NUM_THREADS is null"<<std::endl;
	}
	else {
		NTHREADS = atoi(argv[3]);
    threadsPerBlock = atoi(argv[3]);
	}

  int blocksPerGrid =(total_size + threadsPerBlock - 1) / threadsPerBlock;

  //take the time
  struct timespec start, finish;
  double elapsed;

  //error variable for cuda
  cudaError_t err = cudaSuccess;

  int *h_R, *h_G, *h_B, *h_RED, *h_GREEN, *h_BLUE;
  int *d_R, *d_G, *d_B, *d_RED, *d_GREEN, *d_BLUE;

  //Memory in Host
  h_R = new int[the_size];
  h_G = new int[the_size];
  h_B = new int[the_size];
  h_RED = new int[the_size];
  h_GREEN = new int[the_size];
  h_BLUE = new int[the_size];

  //Fill Arrays RED GREEN BLUE with zero
  randomFill(h_RED, image.rows, image.cols);
  randomFill(h_GREEN, image.rows, image.cols);
  randomFill(h_BLUE, image.rows, image.cols);

  //Fill arrays RGB with data image
  //TODO
  for (int i = 0; i < image.rows; ++i)
  {
    for (int j = 0; j < image.cols; ++j)
    {
      h_R[i*image.cols+j] = image.at<Vec3b>(i,j)[0];
      h_G[i*image.cols+j] = image.at<Vec3b>(i,j)[1];
      h_B[i*image.cols+j] = image.at<Vec3b>(i,j)[2];
    }
  }

  //Memory for cuda in video device
  err = cudaMalloc((void**)&d_R, the_size);
  checkError("Error al reservar memoria para R",err);

  err = cudaMalloc((void**)&d_G, the_size);
  checkError("Error al reservar memoria para G",err);

  err = cudaMalloc((void**)&d_B, the_size);
  checkError("Error al reservar memoria para B",err);

  err = cudaMalloc((void**)&d_RED, the_size);
  checkError("Error al reservar memoria para RED",err);

  err = cudaMalloc((void**)&d_GREEN, the_size);
  checkError("Error al reservar memoria para GREEN",err);

  err = cudaMalloc((void**)&d_BLUE, the_size);
  checkError("Error al reservar memoria para BLUE",err);

  //Copy data matrixes RGB from Host to video device

  err = cudaMemcpy(d_R, h_R, the_size, cudaMemcpyHostToDevice);
  checkError("Error al pasar los datos de RED al device", err);

  err = cudaMemcpy(d_G, h_G, the_size, cudaMemcpyHostToDevice);
  checkError("Error al pasar los datos de GREEN al device", err);

  err = cudaMemcpy(d_B, h_B, the_size, cudaMemcpyHostToDevice);
  checkError("Error al pasar los datos de BLUE al device", err);

  //take the time since execute function
  clock_gettime(CLOCK_MONOTONIC, &start);

  //New Test with more capacity and using if id in __global__ function
  //integer variables declared above
  //int threadsPerBlock = 256;
  //int blocksPerGrid =(total_size + threadsPerBlock - 1) / threadsPerBlock;
  blurEffect<<<blocksPerGrid, threadsPerBlock>>>(d_R,d_G,d_B,d_RED,d_GREEN,d_BLUE,total_size,image.rows,image.cols, radius, NTHREADS);

  //Execute cuda function using for loop
  //blurEffect<<<BLOCKS,NTHREADS/BLOCKS>>>(d_R,d_G,d_B,d_RED,d_GREEN,d_BLUE,total_size,image.rows,image.cols, radius, NTHREADS);

  err = cudaGetLastError();
  checkError("Error al ejecutar el kernel",err);

  //Cuda memory to host
  err = cudaMemcpy(h_RED, d_RED, the_size, cudaMemcpyDeviceToHost);
  checkError("Error al pasar los datos de R al device", err);

  err = cudaMemcpy(h_GREEN, d_GREEN, the_size, cudaMemcpyDeviceToHost);
  checkError("Error al pasar los datos de G al device", err);

  err = cudaMemcpy(h_BLUE, d_BLUE, the_size, cudaMemcpyDeviceToHost);
  checkError("Error al pasar los datos de B al device", err);

  //Move memory to new Mat vector
  for (int i = 0; i < image.rows; ++i)
	{
		for (int j = 0; j < image.cols; ++j)
		{
			blur.at<Vec3b>(i,j)[0] = h_RED[i*image.cols+j];
			blur.at<Vec3b>(i,j)[1] = h_GREEN[i*image.cols+j];
			blur.at<Vec3b>(i,j)[2] = h_BLUE[i*image.cols+j];
		}
	}

  //take the time
  clock_gettime(CLOCK_MONOTONIC, &finish);
  elapsed = (finish.tv_sec - start.tv_sec);
  elapsed += (finish.tv_nsec - start.tv_nsec) / 1000000000.0;
  std::cout<<"Time: "<< elapsed << std::endl;

  //write in file
  std::ofstream output;
  output.open("maincudaResult.txt", std::ofstream::app | std::ofstream::out );
  output<< imageName <<", "<< radius << ", " << threadsPerBlock <<", "<< elapsed << std::endl;
  output.close();

  //free Memory in device
	err=cudaFree(d_R);
	checkError("Error al liberar la memoria del device R",err);
	err=cudaFree(d_G);
	checkError("Error al liberar la memoria del device G",err);
	err=cudaFree(d_B);
	checkError("Error al liberar la memoria del device B",err);
	err=cudaFree(d_RED);
	checkError("Error al liberar la memoria del device RED",err);
  err=cudaFree(d_GREEN);
	checkError("Error al liberar la memoria del device GREEN",err);
  err=cudaFree(d_BLUE);
	checkError("Error al liberar la memoria del device BLUE",err);

	err = cudaDeviceReset();
	checkError("Error al resetear el device",err);

  //free memory in host
  delete h_R;
  delete h_G;
  delete h_B;
  delete h_RED;
  delete h_GREEN;
  delete h_BLUE;

  //write the blur image
  imwrite( "blurimage.jpg", blur );
  //namedWindow( "Blur image", WINDOW_AUTOSIZE );
  //imshow( "Blur image", blur );
  waitKey(0);

  return 0;
}
