#include <stdio.h>
#include <stdlib.h>

int main(){
    FILE *fp1, *fp2;
    char filename[100];
    int ch, next;

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

    while ((ch = getc(fp1)) != EOF) {

        if (ch == '/') {
            next = getc(fp1);

            //Single-line comment
            if (next == '/') {
                while ((ch = getc(fp1)) != '\n' && ch != EOF);
            }

            //Multi-line comment
            else if (next == '*') {
                while (1) {
                    ch = getc(fp1);
                    if (ch == EOF) break;
                    if (ch == '*') {
                        if ((ch = getc(fp1)) == '/')
                            break;
                    }
                }
            }

            //Not a comment
            else {
                putc(ch, fp2);
                putc(next, fp2);
            }
        }
        else {
            putc(ch, fp2);
        }
    }

    fclose(fp1);
    fclose(fp2);

    return 0;
}
