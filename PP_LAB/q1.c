#include <stdio.h>
#include <mpi.h>

int factorial(int num) {
    if (num == 0 || num == 1)
        return 1;
    return num * factorial(num - 1);
}

int main(int argc, char *argv[]) {
    int rank, size, value;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int N = size;
    int arr[N];         

    if (rank == 0) {
        for (int i = 0; i < N; i++) {
            fprintf(stdout,"Enter value to be sent to P%d: ", i);
            fflush(stdout);
            scanf("%d", &arr[i]);
           
        }
    }

    MPI_Scatter(arr, 1, MPI_INT, &value, 1, MPI_INT, 0, MPI_COMM_WORLD);

    int fact = factorial(value);

    int result[N];

    MPI_Gather(&fact, 1, MPI_INT, result, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        int sum = 0;
        for (int i = 0; i < N; i++)
            sum += result[i];

        fprintf(stdout, "Sum of Factorials: %d\n", sum);
        fflush(stdout);
    }

    MPI_Finalize();
    return 0;
}
