#include<stdio.h>
#include<stdlib.h>

int main(){

	FILE *fp1, *fp2;
    char filename[100];
    char line[1000];
    int ch;

    //Input file
    printf("Enter file to be read: ");
    scanf("%s", filename);

    fp1 = fopen(filename, "r");
    if (fp1 == NULL) {
        printf("Cannot open file\n");
        exit(1);
    }

    //Output file
    printf("Enter the output file: ");
    scanf("%s", filename);

    fp2 = fopen(filename, "w");

    //Read line by line
    while(fgets(line, sizeof(line), fp1) != NULL){

    	//skip if it starts with 3
    	if(line[0] == '#')
    		continue;

    	//Writing the non-preprocessor lines
    	fputs(line, fp2);
    }

    fclose(fp1);
    fclose(fp2);

	return 0;
}