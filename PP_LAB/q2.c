#include<stdio.h>
#include<mpi.h>

int main(int argc, char* argv[]){

	int rank, size;
	MPI_Init(&argc, &argv);

	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	int M;

	if(rank == 0){
		fprintf(stdout, "Enter the value for M:");
		fflush(stdout);
		scanf("%d", &M);
	}

	MPI_Bcast(&M, 1, MPI_INT, 0, MPI_COMM_WORLD);

	int recvArr[M];
	int avgArr[size];
	int sendArr[M*size];

	if(rank ==0){

		fprintf(stdout, "Enter the values of the array:");
		fflush(stdout);

		for(int i=0; i<M*size; i++){
			scanf("%d", &sendArr[i]);
		}
	}

	MPI_Scatter(sendArr, M, MPI_INT, &recvArr, M, MPI_INT, 0, MPI_COMM_WORLD);

	int localSum=0;

	//local average
	for(int i=0; i<M; i++){
		localSum += recvArr[i];
	}

	int localAvg= localSum/M;

	fprintf(stdout, "P%d: Local Average: %d\n", rank, localAvg);
	fflush(stdout);

	MPI_Gather(&localAvg, 1, MPI_INT, avgArr, 1, MPI_INT, 0, MPI_COMM_WORLD);

	if(rank == 0){
		int finalSum=0;

		for(int i=0; i<size; i++){
			finalSum += avgArr[i];
		}

		int result = finalSum/size;

		fprintf(stdout, "P0: Final Average:%d \n", result);
		fflush(stdout);

	}

	MPI_Finalize();
	return 0;
}
