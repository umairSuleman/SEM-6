#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>

int isKeyword(char word[]) {
    char *keywords[] = {
        "auto","break","case","char","const","continue","default","do",
        "double","else","enum","extern","float","for","goto","if","int",
        "long","register","return","short","signed","sizeof","static",
        "struct","switch","typedef","union","unsigned","void","volatile","while"
    };

    int n = 32;
    for (int i = 0; i < n; i++) {
        if (strcmp(word, keywords[i]) == 0)
            return 1;
    }
    return 0;
}

void printUpper(char word[]) {
    for (int i = 0; word[i]; i++)
        putc(toupper(word[i]), stdout);
}

int main(){

	FILE *fp;
    char filename[100];
    char word[50];
    int ch, i;

    //Input file
    printf("Enter file to be read: ");
    scanf("%s", filename);

    fp = fopen(filename, "r");
    if (fp == NULL) {
        printf("Cannot open file\n");
        exit(1);
    }

    while((ch= getc(fp)) != EOF){

        //If alpha, form it into a word
        if(isalpha(ch)){
            i=0;
            while(isalpha(ch)){
                word[i++] = ch;
                ch=getc(fp);
            }
            word[i]='\0';

            if(isKeyword(word))
                printUpper(word);
            else
                printf("%s", word);

            ungetc(ch, fp); //push back non-alphabets
        }
        else{
            putc(ch, stdout);
        }
    }

    fclose(fp);
	return 0;
}