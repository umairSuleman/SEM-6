#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fp1, *fp2;
    char filename[100];
    int ch;
    int space_written = 0;

    // Input file
    printf("Enter file to be read: ");
    scanf("%s", filename);

    fp1 = fopen(filename, "r");
    if (fp1 == NULL) {
        printf("Cannot open file\n");
        exit(1);
    }

    // Output file
    printf("Enter the output file: ");
    scanf("%s", filename);

    fp2 = fopen(filename, "w");

    while ((ch = getc(fp1)) != EOF) {

        if (ch == ' ' || ch == '\t') {
            if (!space_written) {
                putc(' ', fp2);
                space_written = 1;
            }
        } 
        else {
            putc(ch, fp2);
            space_written = 0;
        }
    }

    fclose(fp1);
    fclose(fp2);

    return 0;
}
