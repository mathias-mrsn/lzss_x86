<h1 align="center">Lempel–Ziv–Storer–Szymanski (LZSS)</h1>


> LZSS is a lossless data compression algorithm, an improved version of LZ77 made for compressing binary data. It was described by James Storer and Thomas Szymanski in 1982. LZSS is one of the algorithms used in the GIF image format.

## 📝 Table of Contents

- [📋 Prerequisites](#-prerequisites)
- [🚀 Functions](#-functions)

## 📋 Prerequisites

- nasm
- clang
- make

## 📚 Functions

### LzssEncoder `(lzss.h)`

```c
void
LzssEncoder (const void * inputAddr, size_t inputLength, void *outputAddr);
```

### LzssDecoder `(lzss.h)`

```c
void
LzssDecoder (const void * inputAddr, size_t inputLength, void *outputAddr);
```

## 👥 Author

👤 **mamaurai**
* Github: [@mathias-mrsn](https://github.com/mathias-mrsn)
* LinkedIn: [@Mathias MAURAISIN](https://www.linkedin.com/in/mathias-mauraisin)
