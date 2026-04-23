%%writefile str.cu
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda_runtime.h>

__global__ void stringManipulation(char *d_A, int *d_B, int M, int N, char *d_op){
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if(row < M && col < N){
        int index = row * N + col;
        char ch = d_A[index];
        int num = d_B[index];

        int base = 0;
        // Calculate the starting index for this thread's output
        for(int i = 0; i < index; i++){
            base += d_B[i];
        }

        // Write the characters
        for(int i = 0; i < num; i++){
            d_op[base + i] = ch;
        }
    }
}

int main(){
    int M, N;

    printf("Enter Matrix dimensions (M N): ");
    scanf("%d %d", &M, &N);
    
    // Clear the newline character from the input buffer
    getchar(); 

    int size = M * N;

    // Use dynamic allocation instead of VLAs
    char A[size];
    int B[size];

    printf("Enter Matrix A (as a continuous string without spaces): ");
    fgets(A, size + 1, stdin);
    A[strcspn(A, "\n")] = 0; // Remove newline if captured

    printf("Enter Matrix B (space separated integers): ");
    for(int i = 0; i < size; i++){
        scanf("%d", &B[i]);
    }

    // Initialize outputSize to 0
    int outputSize = 0; 
    for(int i = 0; i < size; i++){
        outputSize += B[i];
    }

    // Allocate +1 for the null terminator
    char op[outputSize];

    char *d_A;
    int *d_B;
    char *d_op;

    cudaMalloc((void**)&d_A, size * sizeof(char));
    cudaMalloc((void**)&d_B, size * sizeof(int));
    cudaMalloc((void**)&d_op, outputSize * sizeof(char));

    cudaMemcpy(d_A, A, size * sizeof(char), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, size * sizeof(int), cudaMemcpyHostToDevice);

    dim3 threads(16, 16);
    // Fix grid mapping: N -> x (cols), M -> y (rows)
    dim3 blocks((N + threads.x - 1) / threads.x, (M + threads.y - 1) / threads.y);

    // Fix kernel launch: <<<blocks, threads>>> and pass d_op
    stringManipulation<<<blocks, threads>>>(d_A, d_B, M, N, d_op);

    cudaDeviceSynchronize();

    // Fix Memcpy size: use outputSize instead of size
    cudaMemcpy(op, d_op, outputSize * sizeof(char), cudaMemcpyDeviceToHost);
    op[outputSize] = '\0';

    printf("Output String: %s\n", op);

    // Free all allocated memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_op);

    return 0;
}
