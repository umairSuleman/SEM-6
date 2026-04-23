#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

// CUDA Kernel: Each thread processes one element of the N x N matrix
__global__ void processMatrix(int *d_A, int *d_B, int N) {
    // Determine the row and column this thread is responsible for
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Ensure we don't process outside the matrix boundaries
    if (row < N && col < N) {
        // Flatten 2D index to 1D index
        int index = row * N + col;
        int val = d_A[index];

        // principal diagonal replaced with 0
        if(row == col){
          d_B[index] = 0;
        }
        // above principle diagonal replaced with factorial
        else if(row < col){
          int fact=1;
          for(; val>0; val--){
            fact*=val;
          }
          d_B[index]=fact;
        }
        // below principle diagonal replaced with sum of digits
        else{
          int rem, sum=0;
          while(val != 0){
            rem= val %10;
            sum+=rem;
            num=num/10;
          } 
          d_B[index]=sum;
        }
    }
}

int main() {
    int N = 3; // Number of columns
    int size = N * N * sizeof(int);

    // 1. Allocate and initialize memory on the Host (CPU)
    int *h_A = (int*)malloc(size);
    int *h_B = (int*)malloc(size);

    // Populate the M x N matrix with sample values (1 through 9)
    printf("Original Matrix A (%dx%d):\n", N, N);
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            h_A[i * N + j] = (i * N + j) + 1; 
            printf("%2d ", h_A[i * N + j]);
        }
        printf("\n");
    }
    printf("\n");

    // 2. Allocate memory on the Device (GPU)
    int *d_A, *d_B;
    cudaMalloc((void**)&d_A, size);
    cudaMalloc((void**)&d_B, size);

    // 3. Copy input matrix A from Host to Device
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

    // 4. Configure the 2D Grid and Block dimensions
    // We use a 2D block of 16x16 threads (256 threads total per block)
    dim3 threadsPerBlock(16, 16);
    dim3 blocksPerGrid((N + threadsPerBlock.x - 1) / threadsPerBlock.x, 
                       (M + threadsPerBlock.y - 1) / threadsPerBlock.y);

    // 5. Launch the kernel
    processMatrix<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, N);

    // Wait for GPU to finish
    cudaDeviceSynchronize();

    // 6. Copy the resultant matrix B back to the Host
    cudaMemcpy(h_B, d_B, size, cudaMemcpyDeviceToHost);

    // 7. Print the Resultant Matrix B
    printf("Resultant Matrix B:\n");
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            printf("%2d ", h_B[i * N + j]);
        }
        printf("\n");
    }

    // 8. Free allocated memory
    cudaFree(d_A);
    cudaFree(d_B);
    free(h_A);
    free(h_B);

    return 0;
}
