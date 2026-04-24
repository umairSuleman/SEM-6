#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define MASK_WIDTH 5
#define RADIUS (MASK_WIDTH / 2)
#define TILE_SIZE 256 // Number of threads per block

// 1. Declare the mask in Constant Memory for broadcast performance
__constant__ int d_M[MASK_WIDTH];

// --- CUDA Kernel: Tiled 1D Convolution ---
__global__ void convolution1D_Tiled(int *d_N, int *d_P, int width) {
    // Allocate Shared Memory
    // Size = Tile Size + Left Halo + Right Halo
    __shared__ int N_ds[TILE_SIZE + MASK_WIDTH - 1];

    int tx = threadIdx.x;
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    // 2. Collaborative Memory Loading
    // First, every thread loads its primary element into the middle section of shared memory
    N_ds[tx + RADIUS] = (i < width) ? d_N[i] : 0;

    // Next, the threads on the left edge of the block load the Left Halo cells
    if (tx < RADIUS) {
        // Check for the absolute left boundary of the entire array
        N_ds[tx] = (i - RADIUS >= 0) ? d_N[i - RADIUS] : 0;
    }

    // Finally, the threads on the right edge of the block load the Right Halo cells
    if (tx >= TILE_SIZE - RADIUS) {
        // Check for the absolute right boundary of the entire array
        N_ds[tx + 2 * RADIUS] = (i + RADIUS < width) ? d_N[i + RADIUS] : 0;
    }

    // 3. Synchronize to ensure the entire tile and halos are fully loaded
    __syncthreads();

    // 4. Compute the Convolution
    if (i < width) {
        int Pvalue = 0;
        
        // Loop through the mask. Notice we are reading exclusively from fast Shared and Constant memory!
        for (int j = 0; j < MASK_WIDTH; j++) {
            Pvalue += N_ds[tx + j] * d_M[j];
        }
        
        // Write the final result back to Global Memory
        d_P[i] = Pvalue;
    }
}

// --- Main CPU Program ---
int main() {
    int width = 12; // Input array size
    int size = width * sizeof(int);

    // Host Arrays
    int h_N[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
    int h_M[] = {1, 2, 3, 2, 1}; // Mask
    int h_P[12] = {0};

    printf("Input Array (N): \n");
    for (int i = 0; i < width; i++) printf("%2d ", h_N[i]);
    printf("\n");

    printf("Mask (M): \n");
    for (int i = 0; i < MASK_WIDTH; i++) printf("%2d ", h_M[i]);
    printf("\n\n");

    // Device Pointers
    int *d_N, *d_P;

    // Allocate Global Memory
    cudaMalloc((void**)&d_N, size);
    cudaMalloc((void**)&d_P, size);

    // Copy Input Array to Global Memory
    cudaMemcpy(d_N, h_N, size, cudaMemcpyHostToDevice);

    // Copy Mask to Constant Memory
    cudaMemcpyToSymbol(d_M, h_M, MASK_WIDTH * sizeof(int));

    // Configure Grid and Block dimensions
    int threadsPerBlock = TILE_SIZE;
    int blocksPerGrid = (width + threadsPerBlock - 1) / threadsPerBlock;

    // Launch the Kernel
    convolution1D_Tiled<<<blocksPerGrid, threadsPerBlock>>>(d_N, d_P, width);
    cudaDeviceSynchronize();

    // Copy Result Array back to Host
    cudaMemcpy(h_P, d_P, size, cudaMemcpyDeviceToHost);

    // Print Output Array
    printf("Resultant Array (P): \n");
    for (int i = 0; i < width; i++) {
        printf("%2d ", h_P[i]);
    }
    printf("\n");

    // Free Global Memory
    cudaFree(d_N);
    cudaFree(d_P);

    return 0;
}
