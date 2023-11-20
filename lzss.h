#ifndef LZSS_H
#define LZSS_H

#include <stddef.h>

/**
 * @brief Compress data pointed to by inputAddr
 *
 * This function is an assembly (ASM) implementation of the LZSS algorithm. It replaces
 * every part of the text that has already been seen in the text before.
 * If this is the case, it will replace this text with 11 bits for the position
 * of the first occurrence followed by 4 bits for the length.
 *
 * @param inputAddr Address of the data to compress.
 * @param inputLength The number of bytes to compress.
 * @param outputAddr Address where to put the compressed text.
 *
 * @warning The ouputAddr pointer must be allocated.
 */
extern void
LzssEncoder (void * inputAddr, size_t inputLength, void *outputAddr);
/**
 * @brief Uncompress data pointed to by inputAddr
 *
 * This function is an assembly (ASM) implementation of the LZSS algorithm.
 * It detecte every compressed part in the text, then replace it with
 * the original text.
 *
 * @param inputAddr Address of the data to uncompress.
 * @param inputLength The number of bytes to uncompress.
 * @param outputAddr Address where to put the uncompressed text.
 *
 * @warning The ouputAddr pointer must be allocated.
 */
extern void
LzssDecoder (void * inputAddr, size_t inputLength, void *outputAddr);

#endif
