#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cuda_runtime.h>

#define BLOCK_WIDTH 2
#define TILE_WIDTH 2
#define WIDTH 4

// --- CUDA Kernel: Tiled Matrix Multiplication using Shared Memory ---
__global__ void MatMulElementThreadShared(int *a, int *b, int *c) {
    __shared__ int MDs[TILE_WIDTH][TILE_WIDTH];
    __shared__ int NDs[TILE_WIDTH][TILE_WIDTH];
    
    int m;
    int bx = blockIdx.x; 
    int by = blockIdx.y;
    int tx = threadIdx.x; 
    int ty = threadIdx.y;

    int Row = by * TILE_WIDTH + ty;
    int Col = bx * TILE_WIDTH + tx;

    int Pvalue = 0;
    
    // Loop over the tiles required to compute the dot product
    for(m = 0; m < WIDTH / TILE_WIDTH; m++) {
        
        // Load the tiles into shared memory
        MDs[ty][tx] = a[Row * WIDTH + m * TILE_WIDTH + tx];
        NDs[ty][tx] = b[(m * TILE_WIDTH + ty) * WIDTH + Col];

        // Wait for all threads to finish loading the tile
        __syncthreads();

        // Compute the partial dot product for this tile
        for (int k = 0; k < TILE_WIDTH; k++) {
            Pvalue += MDs[ty][k] * NDs[k][tx];
        }
        
        // Wait for all threads to finish computing before loading the next tile
        __syncthreads();
    }
    
    // Write the final computed value to global memory
    c[Row * WIDTH + Col] = Pvalue;
}

// --- Main CPU Program ---
int main() {
    int *matA, *matB, *matProd;
    int *da, *db, *dc;

    // 1. Allocate and read Matrix A
    printf("\n== Enter elements of Matrix A (4x4) ==\n");
    matA = (int*)malloc(sizeof(int) * WIDTH * WIDTH);
    for(int i = 0; i < WIDTH * WIDTH; i++) {
        scanf("%d", &matA[i]);
    }

    // 2. Allocate and read Matrix B
    printf("\n== Enter elements of Matrix B (4x4) ==\n");
    matB = (int*)malloc(sizeof(int) * WIDTH * WIDTH);
    for(int i = 0; i < WIDTH * WIDTH; i++) {
        scanf("%d", &matB[i]);
    }
    
    // Allocate Host memory for the product matrix
    matProd = (int*)malloc(sizeof(int) * WIDTH * WIDTH);

    // 3. Allocate Device (GPU) memory
    cudaMalloc((void **) &da, sizeof(int) * WIDTH * WIDTH);
    cudaMalloc((void **) &db, sizeof(int) * WIDTH * WIDTH);
    cudaMalloc((void **) &dc, sizeof(int) * WIDTH * WIDTH);

    // 4. Copy data from Host to Device
    cudaMemcpy(da, matA, sizeof(int) * WIDTH * WIDTH, cudaMemcpyHostToDevice);
    cudaMemcpy(db, matB, sizeof(int) * WIDTH * WIDTH, cudaMemcpyHostToDevice);
    
    // 5. Configure Grid and Block dimensions
    int NumBlocks = WIDTH / BLOCK_WIDTH;
    dim3 grid_conf(NumBlocks, NumBlocks);
    dim3 block_conf(BLOCK_WIDTH, BLOCK_WIDTH);

    // 6. Launch the Kernel
    MatMulElementThreadShared<<<grid_conf, block_conf>>>(da, db, dc);
    
    // Wait for the GPU to finish
    cudaDeviceSynchronize();

    // 7. Copy the result back from Device to Host
    cudaMemcpy(matProd, dc, sizeof(int) * WIDTH * WIDTH, cudaMemcpyDeviceToHost);
    
    // 8. Print the Result
    printf("\n= Result of Multiplication =\n");
    printf("--------------------------\n");
    
    // Note: 'm' and 'n' from the original image replaced with 'WIDTH'
    for (int i = 0; i < WIDTH; i++ ) {
        for (int j = 0; j < WIDTH; j++) {
            printf("%6d ", matProd[i * WIDTH + j]);
        }
        printf("\n");
    }

    // 9. Free memory
    cudaFree(da);
    cudaFree(db);
    cudaFree(dc);
    free(matA);
    free(matB);
    free(matProd);

    return 0;
}
