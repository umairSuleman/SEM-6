#include<stdio.h>
#include<mpi.h>
#include<stdlib.h>
#include<ctype.h>
#include<string.h>

int isVowel(char c){
	c=tolower(c);
	return ( c=='a' || c=='e' || c=='i' || c=='o' || c=='u');
}

int countNonVowels( char *str, int len){

	int count=0;
	for(int i=0; i<len; i++){
		if(isalpha(str[i]) && !isVowel(str[i]))
			count++;
	}
	return count;
}

int main(int argc, char *argv[]){

	MPI_Init(&argc, &argv);

	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	char *input_string = NULL;
	int str_len=0;
	int chunk_size;
	char *local_chunk;
	int local_count=0;
	int total_count=0;

	if(rank == 0){

		fprintf(stdout, "Enter a string (length should be divisible by %d):", size);
		fflush(stdout);

		input_string=(char*) malloc(1000 * sizeof(char));
		fgets(input_string, 1000, stdin);

		//remove newline is present
        str_len= strlen(input_string);
        if (input_string[str_len - 1] == '\n') {
            input_string[str_len - 1] = '\0';
            str_len--;
        }

        //check if divisible by N
		if(str_len % size != 0){
			printf("Error: String length not divisible by number of processes\n");
			return 0;
		}

	}

	//broadcasting string length and local chunk sizes
	MPI_Bcast(&str_len, 1, MPI_INT, 0, MPI_COMM_WORLD);

    chunk_size= str_len/ size;

	//allocate mem.
	local_chunk=(char*) malloc((chunk_size + 1) * sizeof(char));

	//scatter the string
	MPI_Scatter(input_string, chunk_size, MPI_CHAR, local_chunk, chunk_size, MPI_CHAR, 0, MPI_COMM_WORLD);

	local_chunk[chunk_size] = '\0';

	//count non-vowels in local chunk
	local_count=countNonVowels(local_chunk, chunk_size);


	printf("Process %d: Non-vowels found: %d (chunk: \"%s\") \n", rank, local_count, local_chunk);

	//reduce to get total count at the roort process
	MPI_Reduce(&local_count, &total_count, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);

	//root prints the total
	if(rank ==0){
		fprintf(stdout, "Total number of non-vowels: %d\n", total_count);
		fflush(stdout);
		free(input_string);
	}
	free(local_chunk);

	MPI_Finalize();
	return 0;
}
