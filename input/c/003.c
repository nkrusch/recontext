#include <stdio.h>
#include <stdlib.h>

void vassume(int b){}
void vtrace1(int x, int y, int z){}

int mainQ(int y, int z) {
    int x=0;
    while (x < 5) {
        vtrace1(x, y, z);
        x = x + 1;
        if (z <= y) {
            y = z;
        }
    }
    return y;
}

void main(int argc, char **argv){
    mainQ(atoi(argv[1]), atoi(argv[2]));
}