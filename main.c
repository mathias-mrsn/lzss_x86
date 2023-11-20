#include "lzss.h"
#include <stdio.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdlib.h>

typedef struct __sSTORED_FILE
{
    void *ptr;
    int32_t fd;
    size_t size;

    const char *_name;
    int32_t _flags;
} STORED_FILE;

STORED_FILE *
sfopen (const char *    file,
        const int32_t   flags)
{
    STORED_FILE sfile = {};

    sfile._name = file;
    sfile.fd = open(file, flags, 0666);
    if (sfile.fd < 0) {
        perror("open()");
        return (NULL);
    }

    if (flags & O_CREAT) {
        if (truncate(file, 10000)) {
            perror("truncate()");
        }
    }

    sfile.size = lseek(sfile.fd, 0, SEEK_END);    
    if (sfile.size < 0) {
        perror("lseek()");
        goto err;
    }

    
    sfile.ptr = mmap(NULL, sfile.size, PROT_READ | ((flags & O_RDWR) ? PROT_WRITE : 0) , MAP_SHARED, sfile.fd, 0);
    if (sfile.ptr == MAP_FAILED) {
        perror("mmap()");
        goto err;
    }

    STORED_FILE * heap_sfile = NULL;

    heap_sfile = (STORED_FILE*)malloc(sizeof(STORED_FILE));
    if (heap_sfile == NULL) {
        perror("malloc()");
        goto err;
    }

    memcpy(heap_sfile, &sfile, sizeof(STORED_FILE));

    return (heap_sfile);

err:
    close(sfile.fd);
    unlink(file);

    return (NULL);
}

int32_t
sfclose (STORED_FILE* sf)
{
    int32_t r = 0;

    r |= munmap(sf->ptr, sf->size);
    if (r < 0)
        perror("mummap()");

    r |= close(sf->fd);
    if (r < 0)
        perror("close()");

    free(sf);
    return (!!r);
}

int
main (int argc, char *argv[])
{
    int             encrypt;
    STORED_FILE     *inputfile;
    STORED_FILE     *outputfile;

    if (argc != 4) {
        printf("Usage: lzss e/d inputfile outputfile\n");
        return 1;
    }
    if (argv[1][1] == 0 && (argv[1][0] == 'd' || argv[1][0] == 'e'))
        encrypt = (argv[1][0] == 'e');
    else {
        printf("invalid argument: %s\n", argv[1]);
        return 1;
    }
    if ((inputfile = sfopen(argv[2], O_RDONLY)) == NULL) {
        printf("invalid inputfile: %s\n", argv[2]);  return 1;
    }
    if ((outputfile = sfopen(argv[3], O_RDWR | O_CREAT)) == NULL) {
        printf("invalid outputfile: %s\n", argv[3]);  return 1;
    }
    if (encrypt)
        LzssEncoder(inputfile->ptr, inputfile->size, outputfile->ptr);
    else
        LzssDecoder(inputfile->ptr, inputfile->size, outputfile->ptr);
    sfclose(inputfile);
    sfclose(outputfile);
    return (0);
}
