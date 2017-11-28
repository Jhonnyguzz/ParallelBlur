/usr/local/cuda-7.5/bin/nvcc maincuda.cu -o maincuda `pkg-config --cflags --libs opencv`

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
