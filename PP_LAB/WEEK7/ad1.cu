#include <stdio.h>
#include <string.h>
#include <cuda_runtime.h>

#define MAX_STR_LEN 1024
#define MAX_WORDS 512

// CUDA Kernel: Each thread reverses one specific word in the string
__global__ void reverseWords(char *d_str, int *d_starts, int *d_lengths, int num_words) {
    // Calculate global thread ID
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    // Ensure we don't go out of bounds if threads > words
    if (tid < num_words) {
        int start = d_starts[tid];
        int len = d_lengths[tid];
        int end = start + len - 1;

        // Swap characters from the outside in (two-pointer approach)
        for (int i = 0; i < len / 2; i++) {
            char temp = d_str[start + i];
            d_str[start + i] = d_str[end - i];
            d_str[end - i] = temp;
        }
    }
}

int main() {
    char str[MAX_STR_LEN];
    
    // 1. Safely read input from the user and strip the newline
    printf("Enter a string of words:\n");
    fgets(str, MAX_STR_LEN, stdin);
    str[strcspn(str, "\n")] = 0; 

    int total_len = strlen(str);
    if (total_len == 0) {
        printf("Empty string provided.\n");
        return 0;
    }

    // Arrays to hold the metadata for each word
    int starts[MAX_WORDS];
    int lengths[MAX_WORDS];
    int num_words = 0;
    int in_word = 0;

    // 2. Host-Side Parsing: Find the start index and length of each word
    for (int i = 0; i <= total_len; i++) {
        // If it's a valid character (not a space and not the null terminator)
        if (str[i] != ' ' && str[i] != '\0') {
            if (!in_word) {
                starts[num_words] = i; // Mark the start of a new word
                in_word = 1;
            }
        } else {
            // We hit a space or the end of the string
            if (in_word) {
                lengths[num_words] = i - starts[num_words]; // Calculate length
                num_words++;
                in_word = 0;
            }
        }
    }

    // Device pointers
    char *d_str;
    int *d_starts, *d_lengths;

    // 3. Allocate memory on the GPU
    // We add +1 to total_len to include the null terminator
    cudaMalloc((void**)&d_str, (total_len + 1) * sizeof(char));
    cudaMalloc((void**)&d_starts, num_words * sizeof(int));
    cudaMalloc((void**)&d_lengths, num_words * sizeof(int));

    // 4. Copy data from Host (CPU) to Device (GPU)
    cudaMemcpy(d_str, str, (total_len + 1) * sizeof(char), cudaMemcpyHostToDevice);
    cudaMemcpy(d_starts, starts, num_words * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_lengths, lengths, num_words * sizeof(int), cudaMemcpyHostToDevice);

    // 5. Configure grid and block dimensions
    int threadsPerBlock = 256;
    int blocksPerGrid = (num_words + threadsPerBlock - 1) / threadsPerBlock;

    // 6. Launch the kernel (N threads for N words)
    reverseWords<<<blocksPerGrid, threadsPerBlock>>>(d_str, d_starts, d_lengths, num_words);

    // Wait for GPU to finish
    cudaDeviceSynchronize();

    // 7. Copy the modified string back to the Host
    cudaMemcpy(str, d_str, (total_len + 1) * sizeof(char), cudaMemcpyDeviceToHost);

    // 8. Print the result and free memory
    printf("\nString with reversed words:\n%s\n", str);

    cudaFree(d_str);
    cudaFree(d_starts);
    cudaFree(d_lengths);

    return 0;
}
