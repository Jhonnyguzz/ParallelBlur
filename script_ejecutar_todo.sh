g++ main.cpp -o main `pkg-config --cflags --libs opencv` -lpthread -lm
g++ mainposix.cpp -o mainposix `pkg-config --cflags --libs opencv` -lpthread -lm
g++ -fopenmp mainopenmp.cpp -o mainopenmp `pkg-config --cflags --libs opencv` -lpthread -lm
/usr/local/cuda-7.5/bin/nvcc maincuda.cu -o maincuda `pkg-config --cflags --libs opencv`
	
#SECUENCIAL

echo "Executing secuencial version 720p image"
for(( radius=2 ; radius<=16 ; radius+=1 ))
do
    ./main 720.jpg $radius
done

echo "Executing secuencial version 1080p image"
for(( radius=2 ; radius<=16 ; radius+=1 ))
do
    ./main 1080.jpg $radius
done

echo "Executing secuencial version 4K image"
for(( radius=2 ; radius<=16 ; radius+=1 ))
do
    ./main 4k.jpg $radius
done

#POSIX

echo "Executing parallel PTHREADS version 720p image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainposix 720.jpg $radius $n_thread
	done
done

echo "Executing parallel PTHREADS version 1080p image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainposix 1080.jpg $radius $n_thread
	done
done

echo "Executing parallel PTHREADS version 4K image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainposix 4k.jpg $radius $n_thread
	done
done

#OPENMP

echo "Executing parallel OPENMP version 720p image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainopenmp 720.jpg $radius $n_thread
	done
done

echo "Executing parallel OPENMP version 1080p image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainopenmp 1080.jpg $radius $n_thread
	done
done

echo "Executing parallel OPENMP version 4K image"
for n_thread in 2 4 8 16
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./mainopenmp 4k.jpg $radius $n_thread
	done
done

#CUDA

echo "Executing parallel with CUDA version 720p image"
for n_thread in 48 96 144 192 256
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./maincuda 720.jpg $radius $n_thread
	done
done

echo "Executing parallel with CUDA version 1080p image"
for n_thread in 48 96 144 192 256
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./maincuda 1080.jpg $radius $n_thread
	done
done

echo "Executing parallel with CUDA version 4K image"
for n_thread in 144 192 256
do
	for(( radius=2 ; radius<=16 ; radius+=1 ))
	do
		./maincuda 4k.jpg $radius $n_thread
	done
done

exit 0
