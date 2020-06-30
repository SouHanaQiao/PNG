//
//  scale.c
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/13.
//  Copyright © 2019 葬花桥. All rights reserved.
//
#include <stdlib.h>
#include <string.h>
#include "scale.h"
#include "khash.h"

// output = (input * MAXOUTSAMPLE / MAXINSAMPLE) + 0.5
#define upscale(input, MAXINSAMPLE, MAXOUTSAMPLE) (((input) * (MAXOUTSAMPLE) / (MAXINSAMPLE)) + 0.5)
#define downscale(input, MAXINSAMPLE, MAXOUTSAMPLE) (((input) * 1.0) * (MAXOUTSAMPLE) / (MAXINSAMPLE) + 0.5)


static inline
unsigned short upscale_uint8_to_uint16(unsigned char component) {
    unsigned short max = 65535;
    return component * (max / (max >> (16 - 8)));
}

static inline
unsigned int upscale_uint8_to_uint32(unsigned char component) {
    unsigned int max = 4294967295;
    return component * (max / (max >> (32 - 8)));
}

static inline
unsigned long long upscale_uint8_to_uint64(unsigned char component) {
    unsigned long long max = 18446744073709551615U;
    return component * (max / (max >> (64 - 8)));
}

static inline
unsigned char downscale_uint16_to_uint8(unsigned short component) {
    return component >> (16 - 8);
}

static inline
unsigned int upscale_uint16_to_uint32(unsigned short component) {
    unsigned int max = 4294967295;
    return component * (max / (max >> (32 - 16)));
}

static inline
unsigned long long upscale_uint16_to_uint64(unsigned short component) {
    unsigned long long max = 18446744073709551615U;
    return component * (max / (max >> (64 - 16)));
}

void convert_index_to_rgba(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth, const unsigned char *palette)
{
    if (inBitDepth < 8) {
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; ++i)
            {
                unsigned char byte = in[i];
                
                for (size_t bit = 0; bit < 8; bit += inBitDepth) {
                    unsigned char index = ((unsigned char)(byte << bit)) >> (8 - inBitDepth);
                    unsigned char palette_r = palette[index * 4];
                    unsigned char palette_g = palette[index * 4 + 1];
                    unsigned char palette_b = palette[index * 4 + 2];
                    unsigned char palette_a = palette[index * 4 + 3];
                    
                    out[j] = palette_r;
                    out[j + 1] = palette_g;
                    out[j + 2] = palette_b;
                    out[j + 3] = palette_a;
                    j += 4;
                }
            }
        } else if (outBitDepth == 16) {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; ++i)
            {
                unsigned char byte = in[i];
                
                for (size_t bit = 0; bit < 8; bit += inBitDepth) {
                    unsigned char index = ((unsigned char)(byte << bit)) >> (8 - inBitDepth);
                    unsigned short palette_r = upscale_uint8_to_uint16(palette[index * 4]);
                    unsigned short palette_g = upscale_uint8_to_uint16(palette[index * 4 + 1]);
                    unsigned short palette_b = upscale_uint8_to_uint16(palette[index * 4 + 2]);
                    unsigned short palette_a = upscale_uint8_to_uint16(palette[index * 4 + 3]);
                    
                    out16[j] = palette_r;
                    out16[j + 1] = palette_g;
                    out16[j + 2] = palette_b;
                    out16[j + 3] = palette_a;
                    j += 4;
                }
            }
        } else if (outBitDepth == 32) {
            unsigned int *out32 = (unsigned int *)out;
            for (size_t i = 0, j = 0; i < length; ++i)
            {
                unsigned char byte = in[i];
                
                for (size_t bit = 0; bit < 8; bit += inBitDepth) {
                    unsigned char index = ((unsigned char)(byte << bit)) >> (8 - inBitDepth);
                    unsigned short palette_r = upscale_uint8_to_uint32(palette[index * 4]);
                    unsigned short palette_g = upscale_uint8_to_uint32(palette[index * 4 + 1]);
                    unsigned short palette_b = upscale_uint8_to_uint32(palette[index * 4 + 2]);
                    unsigned short palette_a = upscale_uint8_to_uint32(palette[index * 4 + 3]);
                    
                    out32[j] = palette_r;
                    out32[j + 1] = palette_g;
                    out32[j + 2] = palette_b;
                    out32[j + 3] = palette_a;
                    j += 4;
                }
            }
        } else {
            unsigned long long *out64 = (unsigned long long *)out;
            for (size_t i = 0, j = 0; i < length; ++i)
            {
                unsigned char byte = in[i];
                
                for (size_t bit = 0; bit < 8; bit += inBitDepth) {
                    unsigned char index = ((unsigned char)(byte << bit)) >> (8 - inBitDepth);
                    unsigned short palette_r = upscale_uint8_to_uint64(palette[index * 4]);
                    unsigned short palette_g = upscale_uint8_to_uint64(palette[index * 4 + 1]);
                    unsigned short palette_b = upscale_uint8_to_uint64(palette[index * 4 + 2]);
                    unsigned short palette_a = upscale_uint8_to_uint64(palette[index * 4 + 3]);
                    
                    out64[j] = palette_r;
                    out64[j + 1] = palette_g;
                    out64[j + 2] = palette_b;
                    out64[j + 3] = palette_a;
                    j += 4;
                }
            }
        }
    } else if (inBitDepth == 8) {
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; ++i, j += 4)
            {
                unsigned char index = in[i];
                unsigned char palette_r = palette[index * 4];
                unsigned char palette_g = palette[index * 4 + 1];
                unsigned char palette_b = palette[index * 4 + 2];
                unsigned char palette_a = palette[index * 4 + 3];
                
                out[j] = palette_r;
                out[j + 1] = palette_g;
                out[j + 2] = palette_b;
                out[j + 3] = palette_a;
            }
        } else if (outBitDepth == 16) {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; ++i, j += 4)
            {
                unsigned char index = in[i];
                unsigned short palette_r = upscale_uint8_to_uint16(palette[index * 4]);
                unsigned short palette_g = upscale_uint8_to_uint16(palette[index * 4 + 1]);
                unsigned short palette_b = upscale_uint8_to_uint16(palette[index * 4 + 2]);
                unsigned short palette_a = upscale_uint8_to_uint16(palette[index * 4 + 3]);
                
                out16[j] = palette_r;
                out16[j + 1] = palette_g;
                out16[j + 2] = palette_b;
                out16[j + 3] = palette_a;
            }
        } else {
            unsigned long long *out64 = (unsigned long long *)out;
            for (size_t i = 0, j = 0; i < length; ++i, j += 4)
            {
                unsigned char index = in[i];
                unsigned long long palette_r = upscale_uint8_to_uint64(palette[index * 4]);
                unsigned long long palette_g = upscale_uint8_to_uint64(palette[index * 4 + 1]);
                unsigned long long palette_b = upscale_uint8_to_uint64(palette[index * 4 + 2]);
                unsigned long long palette_a = upscale_uint8_to_uint64(palette[index * 4 + 3]);
                
                out64[j] = palette_r;
                out64[j + 1] = palette_g;
                out64[j + 2] = palette_b;
                out64[j + 3] = palette_a;
            }
        }
    }
}

void convert_index_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned char paletteR = palette[index * 4];
            unsigned char paletteG = palette[index * 4 + 1];
            unsigned char paletteB = palette[index * 4 + 2];
            unsigned char paletteA = palette[index * 4 + 3];
            
            out[j] = paletteR;
            out[j + 1] = paletteG;
            out[j + 2] = paletteB;
            out[j + 3] = paletteA;
            j += 4;
        }
    }
}

void convert_index_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned short paletteR = upscale_uint8_to_uint16(palette[index * 4]);
            unsigned short paletteG = upscale_uint8_to_uint16(palette[index * 4 + 1]);
            unsigned short paletteB = upscale_uint8_to_uint16(palette[index * 4 + 2]);
            unsigned short paletteA = upscale_uint8_to_uint16(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            out[j + 1] = paletteG;
            out[j + 2] = paletteB;
            out[j + 3] = paletteA;
            j += 4;
        }
    }
}

void convert_index_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned short paletteR = upscale_uint8_to_uint32(palette[index * 4]);
            unsigned short paletteG = upscale_uint8_to_uint32(palette[index * 4 + 1]);
            unsigned short paletteB = upscale_uint8_to_uint32(palette[index * 4 + 2]);
            unsigned short paletteA = upscale_uint8_to_uint32(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            out[j + 1] = paletteG;
            out[j + 2] = paletteB;
            out[j + 3] = paletteA;
            j += 4;
        }
    }
}

void convert_index_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned short paletteR = upscale_uint8_to_uint64(palette[index * 4]);
            unsigned short paletteG = upscale_uint8_to_uint64(palette[index * 4 + 1]);
            unsigned short paletteB = upscale_uint8_to_uint64(palette[index * 4 + 2]);
            unsigned short paletteA = upscale_uint8_to_uint64(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            out[j + 1] = paletteG;
            out[j + 2] = paletteB;
            out[j + 3] = paletteA;
            j += 4;
        }
    }
}


void convert_index8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 4)
    {
        unsigned char index = in[i];
        unsigned char paletteR = palette[index * 4];
        unsigned char paletteG = palette[index * 4 + 1];
        unsigned char paletteB = palette[index * 4 + 2];
        unsigned char paletteA = palette[index * 4 + 3];
        
        out[j] = paletteR;
        out[j + 1] = paletteG;
        out[j + 2] = paletteB;
        out[j + 3] = paletteA;
    }
}

void convert_index8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 4)
    {
        unsigned char index = in[i];
        unsigned short paletteR = upscale_uint8_to_uint16(palette[index * 4]);
        unsigned short paletteG = upscale_uint8_to_uint16(palette[index * 4 + 1]);
        unsigned short paletteB = upscale_uint8_to_uint16(palette[index * 4 + 2]);
        unsigned short paletteA = upscale_uint8_to_uint16(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteG;
        out[j + 2] = paletteB;
        out[j + 3] = paletteA;
    }
}

void convert_index8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 4)
    {
        unsigned char index = in[i];
        unsigned int paletteR = upscale_uint8_to_uint32(palette[index * 4]);
        unsigned int paletteG = upscale_uint8_to_uint32(palette[index * 4 + 1]);
        unsigned int paletteB = upscale_uint8_to_uint32(palette[index * 4 + 2]);
        unsigned int paletteA = upscale_uint8_to_uint32(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteG;
        out[j + 2] = paletteB;
        out[j + 3] = paletteA;
    }
}

void convert_index8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 4)
    {
        unsigned char index = in[i];
        unsigned long long paletteR = upscale_uint8_to_uint64(palette[index * 4]);
        unsigned long long paletteG = upscale_uint8_to_uint64(palette[index * 4 + 1]);
        unsigned long long paletteB = upscale_uint8_to_uint64(palette[index * 4 + 2]);
        unsigned long long paletteA = upscale_uint8_to_uint64(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteG;
        out[j + 2] = paletteB;
        out[j + 3] = paletteA;
    }
}


void convert_v_to_rgba(const unsigned char *in, unsigned char *out, size_t length, size_t type, unsigned char bitDepth, const unsigned short *chromaKey)
{
    switch (type) {
        case 8:
            convert_v_to_rgba8(in, out, length, bitDepth, chromaKey);
            break;
        case 16:
            convert_v_to_rgba16(in, (unsigned short *)out, length, bitDepth, chromaKey);
            break;
        case 32:
            convert_v_to_rgba32(in, (unsigned int *)out, length, bitDepth, chromaKey);
            break;
        case 64:
            convert_v_to_rgba64(in, (unsigned long long *)out, length, bitDepth, chromaKey);
            break;
        default:
            break;
    }
}

void convert_v_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    unsigned char maxOutSample = (1 << bitDepth) - 1;
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned char value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 255);
                unsigned char r = value;
                unsigned char g = value;
                unsigned char b = value;
                unsigned char a = 255;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = g;
                out[j + 2] = b;
                out[j + 3] = a;
                j += 4;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned char value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 255);
                
                out[j] = value;
                out[j + 1] = value;
                out[j + 2] = value;
                out[j + 3] = 255;
                j += 4;
            }
        }
    }
}

void convert_v_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    unsigned char maxOutSample = (1 << bitDepth) - 1;
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned short value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 65535);
                unsigned short r = value;
                unsigned short g = value;
                unsigned short b = value;
                unsigned short a = 65535;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = g;
                out[j + 2] = b;
                out[j + 3] = a;
                j += 4;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned short value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 65535);
                
                out[j] = value;
                out[j + 1] = value;
                out[j + 2] = value;
                out[j + 3] = 65535;
                j += 4;
            }
        }
    }
}

void convert_v_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    unsigned char maxOutSample = (1 << bitDepth) - 1;
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned int value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 4294967295);
                unsigned int r = value;
                unsigned int g = value;
                unsigned int b = value;
                unsigned int a = 4294967295;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = g;
                out[j + 2] = b;
                out[j + 3] = a;
                j += 4;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned int value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 4294967295);
                
                out[j] = value;
                out[j + 1] = value;
                out[j + 2] = value;
                out[j + 3] = 4294967295;
                j += 4;
            }
        }
    }
}

void convert_v_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    unsigned char maxOutSample = (1 << bitDepth) - 1;
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned long long value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 18446744073709551615U);
                unsigned long long r = value;
                unsigned long long g = value;
                unsigned long long b = value;
                unsigned long long a = 18446744073709551615U;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = g;
                out[j + 2] = b;
                out[j + 3] = a;
                j += 4;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned long long value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxOutSample, 18446744073709551615U);
                
                out[j] = value;
                out[j + 1] = value;
                out[j + 2] = value;
                out[j + 3] = 18446744073709551615U;
                j += 4;
            }
        }
    }
}

void convert_v8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned char value = in[i];
            unsigned char r = value;
            unsigned char g = value;
            unsigned char b = value;
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned char value = in[i];
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 255;
        }
    }
}

void convert_v8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned short value = upscale_uint8_to_uint16(in[i]);
            unsigned short r = value;
            unsigned short g = value;
            unsigned short b = value;
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned short value = upscale_uint8_to_uint16(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 65535;
        }
    }
}

void convert_v8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned int value = upscale_uint8_to_uint32(in[i]);
            unsigned int r = value;
            unsigned int g = value;
            unsigned int b = value;
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned int value = upscale_uint8_to_uint32(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 4294967295;
        }
    }
}

void convert_v8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned long long value = upscale_uint8_to_uint64(in[i]);
            unsigned long long r = value;
            unsigned long long g = value;
            unsigned long long b = value;
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned long long value = upscale_uint8_to_uint64(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 18446744073709551615U;
        }
    }
}

void convert_v16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned char value = downscale_uint16_to_uint8(in[i]);
            unsigned char r = value;
            unsigned char g = value;
            unsigned char b = value;
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned char value = downscale_uint16_to_uint8(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 255;
        }
    }
}

void convert_v16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned short value = in[i];
            unsigned short r = value;
            unsigned short g = value;
            unsigned short b = value;
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned short value = in[i];
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 65535;
        }
    }
}

void convert_v16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned int value = upscale_uint16_to_uint32(in[i]);
            unsigned int r = value;
            unsigned int g = value;
            unsigned int b = value;
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned int value = upscale_uint16_to_uint32(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 4294967295;
        }
    }
}

void convert_v16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned long long value = upscale_uint16_to_uint64(in[i]);
            unsigned long long r = value;
            unsigned long long g = value;
            unsigned long long b = value;
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 4)
        {
            unsigned long long value = upscale_uint16_to_uint64(in[i]);
            out[j] = value;
            out[j + 1] = value;
            out[j + 2] = value;
            out[j + 3] = 18446744073709551615U;
        }
    }
}


void convert_va8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned char value = in[i];
        unsigned char alpha = in[i + 1];
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned short value = upscale_uint8_to_uint16(in[i]);
        unsigned short alpha = upscale_uint8_to_uint16(in[i + 1]);
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned int value = upscale_uint8_to_uint32(in[i]);
        unsigned int alpha = upscale_uint8_to_uint32(in[i + 1]);
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned long long value = upscale_uint8_to_uint64(in[i]);
        unsigned long long alpha = upscale_uint8_to_uint64(in[i + 1]);
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned char value = downscale_uint16_to_uint8(in[i]);
        unsigned char alpha = downscale_uint16_to_uint8(in[i + 1]);
        
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned short value = in[i];
        unsigned short alpha = in[i + 1];
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned int value = upscale_uint16_to_uint32(in[i]);
        unsigned int alpha = upscale_uint16_to_uint32(in[i + 1]);
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}

void convert_va16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 2, j += 4)
    {
        unsigned long long value = upscale_uint16_to_uint64(in[i]);
        unsigned long long alpha = upscale_uint16_to_uint64(in[i + 1]);
        out[j] = value;
        out[j + 1] = value;
        out[j + 2] = value;
        out[j + 3] = alpha;
    }
}


void convert_rgb8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned char r = in[i];
            unsigned char g = in[i + 1];
            unsigned char b = in[i + 2];
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = in[i];
            out[j + 1] = in[i + 1];
            out[j + 2] = in[i + 2];
            out[j + 3] = 255;
        }
    }
}

void convert_rgb8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned short r = upscale_uint8_to_uint16(in[i]);
            unsigned short g = upscale_uint8_to_uint16(in[i + 1]);
            unsigned short b = upscale_uint8_to_uint16(in[i + 2]);
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = upscale_uint8_to_uint16(in[i]);
            out[j + 1] = upscale_uint8_to_uint16(in[i + 1]);
            out[j + 2] = upscale_uint8_to_uint16(in[i + 2]);
            out[j + 3] = 65535;
        }
    }
}

void convert_rgb8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned int r = upscale_uint8_to_uint32(in[i]);
            unsigned int g = upscale_uint8_to_uint32(in[i + 1]);
            unsigned int b = upscale_uint8_to_uint32(in[i + 2]);
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = upscale_uint8_to_uint32(in[i]);
            out[j + 1] = upscale_uint8_to_uint32(in[i + 1]);
            out[j + 2] = upscale_uint8_to_uint32(in[i + 2]);
            out[j + 3] = 4294967295;
        }
    }
}

void convert_rgb8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned long long r = upscale_uint8_to_uint64(in[i]);
            unsigned long long g = upscale_uint8_to_uint64(in[i + 1]);
            unsigned long long b = upscale_uint8_to_uint64(in[i + 2]);
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = upscale_uint8_to_uint64(in[i]);
            out[j + 1] = upscale_uint8_to_uint64(in[i + 1]);
            out[j + 2] = upscale_uint8_to_uint64(in[i + 2]);
            out[j + 3] = 18446744073709551615U;
        }
    }
}

void convert_rgb16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned char r = downscale_uint16_to_uint8(in[i]);
            unsigned char g = downscale_uint16_to_uint8(in[i + 1]);
            unsigned char b = downscale_uint16_to_uint8(in[i + 2]);
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = downscale_uint16_to_uint8(in[i]);
            out[j + 1] = downscale_uint16_to_uint8(in[i + 1]);
            out[j + 2] = downscale_uint16_to_uint8(in[i + 2]);
            out[j + 3] = 255;
        }
    }
}

void convert_rgb16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned short r = in[i];
            unsigned short g = in[i + 1];
            unsigned short b = in[i + 2];
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = in[i];
            out[j + 1] = in[i + 1];
            out[j + 2] = in[i + 2];
            out[j + 3] = 65535;
        }
    }
}

void convert_rgb16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned int r = upscale_uint16_to_uint32(in[i]);
            unsigned int g = upscale_uint16_to_uint32(in[i + 1]);
            unsigned int b = upscale_uint16_to_uint32(in[i + 2]);
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = upscale_uint16_to_uint32(in[i]);
            out[j + 1] = upscale_uint16_to_uint32(in[i + 1]);
            out[j + 2] = upscale_uint16_to_uint32(in[i + 2]);
            out[j + 3] = 4294967295;
        }
    }
}

void convert_rgb16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            unsigned long long r = upscale_uint16_to_uint64(in[i]);
            unsigned long long g = upscale_uint16_to_uint64(in[i + 1]);
            unsigned long long b = upscale_uint16_to_uint64(in[i + 2]);
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = g;
            out[j + 2] = b;
            out[j + 3] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 4)
        {
            out[j] = upscale_uint16_to_uint64(in[i]);
            out[j + 1] = upscale_uint16_to_uint64(in[i + 1]);
            out[j + 2] = upscale_uint16_to_uint64(in[i + 2]);
            out[j + 3] = 18446744073709551615U;
        }
    }
}


void convert_rgba8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length) {
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint16(in[i]);
    }
}

void convert_rgba8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint32(in[i]);
    }
}

void convert_rgba8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint64(in[i]);
    }
}

void convert_rgba16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length) {
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = downscale_uint16_to_uint8(in[i]);
    }
}

void convert_rgba16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length) {
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint16_to_uint32(in[i]);
    }
}

void convert_rgba16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length) {
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint16_to_uint64(in[i]);
    }
}



void convert_index_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned char paletteR = palette[index * 4];
            unsigned char paletteA = palette[index * 4 + 3];
            
            out[j] = paletteR;
            
            out[j + 1] = paletteA;
            j += 2;
        }
    }
}

void convert_index_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned short paletteR = upscale_uint8_to_uint16(palette[index * 4]);
            unsigned short paletteA = upscale_uint8_to_uint16(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            
            out[j + 1] = paletteA;
            j += 2;
        }
    }
}

void convert_index_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned int paletteR = upscale_uint8_to_uint32(palette[index * 4]);
            unsigned int paletteA = upscale_uint8_to_uint32(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            
            out[j + 1] = paletteA;
            j += 2;
        }
    }
}

void convert_index_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i)
    {
        unsigned char byte = in[i];
        
        for (size_t bit = 0; bit < 8; bit += bitDepth) {
            unsigned char index = ((unsigned char)(byte << bit)) >> (8 - bitDepth);
            unsigned long long paletteR = upscale_uint8_to_uint64(palette[index * 4]);
            unsigned long long paletteA = upscale_uint8_to_uint64(palette[index * 4 + 3]);
            
            out[j] = paletteR;
            
            out[j + 1] = paletteA;
            j += 2;
        }
    }
}


void convert_index8_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 2)
    {
        unsigned char index = in[i];
        unsigned char paletteR = palette[index * 4];
        unsigned char paletteA = palette[index * 4 + 3];
        
        out[j] = paletteR;
        out[j + 1] = paletteA;
    }
}

void convert_index8_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 2)
    {
        unsigned char index = in[i];
        unsigned short paletteR = upscale_uint8_to_uint16(palette[index * 4]);
        unsigned short paletteA = upscale_uint8_to_uint16(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteA;
    }
}

void convert_index8_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 2)
    {
        unsigned char index = in[i];
        unsigned int paletteR = upscale_uint8_to_uint32(palette[index * 4]);
        unsigned int paletteA = upscale_uint8_to_uint32(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteA;
    }
}

void convert_index8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette)
{
    for (size_t i = 0, j = 0; i < length; ++i, j += 2)
    {
        unsigned char index = in[i];
        unsigned long long paletteR = upscale_uint8_to_uint64(palette[index * 4]);
        unsigned long long paletteA = upscale_uint8_to_uint64(palette[index * 4 + 3]);
        
        out[j] = paletteR;
        out[j + 1] = paletteA;
    }
}


void convert_v_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    unsigned short maxInSample = (1 << bitDepth) - 1;
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned char value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxInSample, 255);
                unsigned char r = value;
                unsigned char g = value;
                unsigned char b = value;
                unsigned char a = 255;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = a;
                j += 2;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned char value = upscale(((unsigned char)(byte << bit)) >> (8 - bitDepth), maxInSample, 255);
                unsigned char a = 255;
                
                out[j] = value;
                out[j + 1] = a;
                j += 2;
            }
        }
    }
}

void convert_v_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned short value = upscale_uint8_to_uint16(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned short r = value;
                unsigned short g = value;
                unsigned short b = value;
                unsigned short a = 65535;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = a;
                j += 2;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned short value = upscale_uint8_to_uint16(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned short a = 65535;
                
                out[j] = value;
                out[j + 1] = a;
                j += 2;
            }
        }
    }
}

void convert_v_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned int value = upscale_uint8_to_uint32(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned int r = value;
                unsigned int g = value;
                unsigned int b = value;
                unsigned int a = 4294967295;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = a;
                j += 2;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned int value = upscale_uint8_to_uint32(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned int a = 4294967295;
                
                out[j] = value;
                out[j + 1] = a;
                j += 2;
            }
        }
    }
}

void convert_v_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned long long value = upscale_uint8_to_uint64(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned long long r = value;
                unsigned long long g = value;
                unsigned long long b = value;
                unsigned long long a = 18446744073709551615U;
                
                if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                    a = 0;
                }
                
                out[j] = r;
                out[j + 1] = a;
                j += 2;
            }
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i)
        {
            unsigned char byte = in[i];
            for (size_t bit = 0; bit < 8; bit += bitDepth) {
                unsigned long long value = upscale_uint8_to_uint64(((unsigned char)(byte << bit)) >> (8 - bitDepth));
                unsigned long long a = 18446744073709551615U;
                
                out[j] = value;
                out[j + 1] = a;
                j += 2;
            }
        }
    }
}


void convert_v8_to_va8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned char value = in[i];
            unsigned char r = value;
            unsigned char g = value;
            unsigned char b = value;
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned char value = in[i];
            out[j] = value;
            out[j + 1] = 255;
        }
    }
}

void convert_v8_to_va16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned short value = upscale_uint8_to_uint16(in[i]);
            unsigned short r = value;
            unsigned short g = value;
            unsigned short b = value;
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned short value = upscale_uint8_to_uint16(in[i]);
            out[j] = value;
            out[j + 1] = 65535;
        }
    }
}

void convert_v8_to_va32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned int value = upscale_uint8_to_uint32(in[i]);
            unsigned int r = value;
            unsigned int g = value;
            unsigned int b = value;
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned int value = upscale_uint8_to_uint32(in[i]);
            out[j] = value;
            out[j + 31] = 4294967295;
        }
    }
}

void convert_v8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned long long value = upscale_uint8_to_uint64(in[i]);
            unsigned long long r = value;
            unsigned long long g = value;
            unsigned long long b = value;
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned long long value = upscale_uint8_to_uint64(in[i]);
            out[j] = value;
            out[j + 1] = 18446744073709551615U;
        }
    }
}


void convert_v16_to_va8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned char value = downscale_uint16_to_uint8(in[i]);
            unsigned char r = value;
            unsigned char g = value;
            unsigned char b = value;
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned char value = downscale_uint16_to_uint8(in[i]);
            out[j] = value;
            out[j + 1] = 255;
        }
    }
}

void convert_v16_to_va16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned short value = in[i];
            unsigned short r = value;
            unsigned short g = value;
            unsigned short b = value;
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned short value = in[i];
            out[j] = value;
            out[j + 1] = 65535;
        }
    }
}

void convert_v16_to_va32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned int value = upscale_uint16_to_uint32(in[i]);
            unsigned int r = value;
            unsigned int g = value;
            unsigned int b = value;
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned int value = upscale_uint16_to_uint32(in[i]);
            out[j] = value;
            out[j + 1] = 4294967295;
        }
    }
}

void convert_v16_to_va64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey)
{
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned long long value = upscale_uint16_to_uint64(in[i]);
            unsigned long long r = value;
            unsigned long long g = value;
            unsigned long long b = value;
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; ++i, j += 2)
        {
            unsigned long long value = upscale_uint16_to_uint64(in[i]);
            out[j] = value;
            out[j + 1] = 18446744073709551615U;
        }
    }
}

void convert_va8_to_va16(const unsigned char *in, unsigned short *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint16(in[i]);
    }
}

void convert_va8_to_va32(const unsigned char *in, unsigned int *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint32(in[i]);
    }
}

void convert_va8_to_va64(const unsigned char *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint8_to_uint64(in[i]);
    }
}


void convert_va16_to_va8(const unsigned short *in, unsigned char *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = downscale_uint16_to_uint8(in[i]);
    }
}

void convert_va16_to_va32(const unsigned short *in, unsigned int *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint16_to_uint32(in[i]);
    }
}

void convert_va16_to_va64(const unsigned short *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0; i < length; ++i)
    {
        out[i] = upscale_uint16_to_uint64(in[i]);
    }
}


void convert_rgb8_to_va8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned char r = in[i];
            unsigned char g = in[i + 1];
            unsigned char b = in[i + 2];
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = in[i];
            out[j + 1] = 255;
        }
    }
}

void convert_rgb8_to_va16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned short r = upscale_uint8_to_uint16(in[i]);
            unsigned short g = upscale_uint8_to_uint16(in[i + 1]);
            unsigned short b = upscale_uint8_to_uint16(in[i + 2]);
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = upscale_uint8_to_uint16(in[i]);
            out[j + 1] = 65535;
        }
    }
}

void convert_rgb8_to_va32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned int r = upscale_uint8_to_uint32(in[i]);
            unsigned int g = upscale_uint8_to_uint32(in[i + 1]);
            unsigned int b = upscale_uint8_to_uint32(in[i + 2]);
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = upscale_uint8_to_uint32(in[i]);
            out[j + 1] = 4294967295;
        }
    }
}

void convert_rgb8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned long long r = upscale_uint8_to_uint64(in[i]);
            unsigned long long g = upscale_uint8_to_uint64(in[i + 1]);
            unsigned long long b = upscale_uint8_to_uint64(in[i + 2]);
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = upscale_uint8_to_uint64(in[i]);
            out[j + 1] = 18446744073709551615U;
        }
    }
}

void convert_rgb16_to_va8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = downscale_uint16_to_uint8(chromaKey[0]);
        unsigned char chromaKeyG = downscale_uint16_to_uint8(chromaKey[1]);
        unsigned char chromaKeyB = downscale_uint16_to_uint8(chromaKey[2]);
        unsigned char chromaKeyA = downscale_uint16_to_uint8(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned char r = downscale_uint16_to_uint8(in[i]);
            unsigned char g = downscale_uint16_to_uint8(in[i + 1]);
            unsigned char b = downscale_uint16_to_uint8(in[i + 2]);
            unsigned char a = 255;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = downscale_uint16_to_uint8(in[i]);
            out[j + 2] = 255;
        }
    }
}

void convert_rgb16_to_va16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = chromaKey[0];
        unsigned char chromaKeyG = chromaKey[1];
        unsigned char chromaKeyB = chromaKey[2];
        unsigned char chromaKeyA = chromaKey[3];
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned short r = in[i];
            unsigned short g = in[i + 1];
            unsigned short b = in[i + 2];
            unsigned short a = 65535;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = in[i];
            out[j + 1] = 65535;
        }
    }
}

void convert_rgb16_to_va32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint32(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint32(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint32(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint32(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned int r = upscale_uint16_to_uint32(in[i]);
            unsigned int g = upscale_uint16_to_uint32(in[i + 1]);
            unsigned int b = upscale_uint16_to_uint32(in[i + 2]);
            unsigned int a = 4294967295;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = upscale_uint16_to_uint32(in[i]);
            out[j + 1] = 4294967295;
        }
    }
}

void convert_rgb16_to_va64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey) {
    if (chromaKey) {
        unsigned char chromaKeyR = upscale_uint16_to_uint64(chromaKey[0]);
        unsigned char chromaKeyG = upscale_uint16_to_uint64(chromaKey[1]);
        unsigned char chromaKeyB = upscale_uint16_to_uint64(chromaKey[2]);
        unsigned char chromaKeyA = upscale_uint16_to_uint64(chromaKey[3]);
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            unsigned long long r = upscale_uint16_to_uint64(in[i]);
            unsigned long long g = upscale_uint16_to_uint64(in[i + 1]);
            unsigned long long b = upscale_uint16_to_uint64(in[i + 2]);
            unsigned long long a = 18446744073709551615U;
            
            if (r == chromaKeyR && g == chromaKeyG && b == chromaKeyB && a == chromaKeyA) {
                a = 0;
            }
            
            out[j] = r;
            out[j + 1] = a;
        }
    } else {
        for (size_t i = 0, j = 0; i < length; i += 3, j += 2)
        {
            out[j] = upscale_uint16_to_uint64(in[i]);
            out[j + 1] = 18446744073709551615U;
        }
    }
}

void convert_rgba8_to_va8(const unsigned char *in, unsigned char *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = in[i];
        out[j + 1] = in[i + 3];
    }
}

void convert_rgba8_to_va16(const unsigned char *in, unsigned short *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = upscale_uint8_to_uint16(in[i]);
        out[j + 1] = upscale_uint8_to_uint16(in[i + 3]);
    }
}

void convert_rgba8_to_va32(const unsigned char *in, unsigned int *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = upscale_uint8_to_uint32(in[i]);
        out[j + 1] = upscale_uint8_to_uint32(in[i + 3]);
    }
}

void convert_rgba8_to_va64(const unsigned char *in, unsigned long long *out, size_t length)
{
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = upscale_uint8_to_uint64(in[i]);
        out[j + 1] = upscale_uint8_to_uint64(in[i + 3]);
    }
}

void convert_rgba16_to_va8(const unsigned short *in, unsigned char *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = downscale_uint16_to_uint8(in[i]);
        out[j + 1] = downscale_uint16_to_uint8(in[i + 3]);
    }
}

void convert_rgba16_to_va16(const unsigned short *in, unsigned short *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = in[i];
        out[j + 1] = in[i + 3];
    }
}

void convert_rgba16_to_va32(const unsigned short *in, unsigned int *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = upscale_uint16_to_uint32(in[i]);
        out[j + 1] = upscale_uint16_to_uint32(in[i + 3]);
    }
}

void convert_rgba16_to_va64(const unsigned short *in, unsigned long long *out, size_t length) {
    for (size_t i = 0, j = 0; i < length; i += 4, j += 2)
    {
        out[j] = upscale_uint16_to_uint64(in[i]);
        out[j + 1] = upscale_uint16_to_uint64(in[i + 3]);
    }
}

// MARK: - RGBA to other color
void convert_rgba_to_v(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth)
{
    unsigned short maxOutSample = (1 << outBitDepth) - 1;
    if (outBitDepth <= 8) {
        
        if (inBitDepth == 8) {
            char bit = 8 - outBitDepth;
            for (size_t i = 0, j = 0; i < length; i += 4) {
                unsigned char r = in[i];
                unsigned char v = downscale(r, 255, maxOutSample); // r >> (8 - outBitDepth);
                out[j] = out[j] | (v << bit);
                
                bit -= outBitDepth;
                if (bit < 0) {
                    bit = 8 - outBitDepth;
                    j += 1;
                }
            }
        } else if (inBitDepth == 16) {
            unsigned short *in16 = (unsigned short *)in;
            char bit = 8 - outBitDepth;
            for (size_t i = 0, j = 0; i < length; i += 4) {
                unsigned short r = in16[i];
                unsigned char v = downscale(r, 65535, maxOutSample);
                out[j] = out[j] | (v << bit);
                
                bit -= outBitDepth;
                if (bit < 0) {
                    bit = 8 - outBitDepth;
                    j += 1;
                }
            }
        } else if (inBitDepth == 32) {
            unsigned int *in32 = (unsigned int *)in;
            char bit = 8 - outBitDepth;
            for (size_t i = 0, j = 0; i < length; i += 4) {
                unsigned int r = in32[i];
                unsigned char v = downscale(r, 4294967295, maxOutSample);
                out[j] = out[j] | (v << bit);
                
                bit -= outBitDepth;
                if (bit < 0) {
                    bit = 8 - outBitDepth;
                    j += 1;
                }
            }
        } else {
            unsigned long long *in64 = (unsigned long long *)in;
            char bit = 8 - outBitDepth;
            for (size_t i = 0, j = 0; i < length; i += 4) {
                unsigned long long r = in64[i];
                unsigned char v = downscale(r, 18446744073709551615U, maxOutSample);
                out[j] = out[j] | (v << bit);
                
                bit -= outBitDepth;
                if (bit < 0) {
                    bit = 8 - outBitDepth;
                    j += 1;
                }
            }
        }
    } else {
        if (inBitDepth == 8) {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, ++j) {
                unsigned char r = in[i];
                unsigned short v = upscale_uint8_to_uint16(r);
                out16[j] = v;
            }
        } else if (inBitDepth == 16) {
            unsigned short *in16 = (unsigned short *)in;
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, ++j) {
                unsigned short r = in16[i];
                unsigned short v = r;
                out16[j] = v;
            }
        } else if (inBitDepth == 32) {
            unsigned short *in32 = (unsigned short *)in;
            unsigned short *out32 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, ++j) {
                unsigned int r = in32[i];
                unsigned short v = downscale(r, 4294967295, maxOutSample);
                out32[j] = v;
            }
        } else {
            unsigned short *in64 = (unsigned short *)in;
            unsigned short *out64 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, ++j) {
                unsigned long long r = in64[i];
                unsigned short v = downscale(r, 18446744073709551615U, maxOutSample);
                out64[j] = v;
            }
        }
    }
}

void convert_rgba_to_va(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth)
{
    unsigned char maxInSample = (1 << inBitDepth) - 1;
    if (inBitDepth == 8) {
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out[j] = in[i];
                out[j + 1] = in[i + 3];
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out16[j] = upscale_uint8_to_uint16(in[i]);
                out16[j + 1] = upscale_uint8_to_uint16(in[i + 3]);
            }
        }
    } else if (inBitDepth == 16) {
        unsigned short *in16 = (unsigned short *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out[j] = downscale_uint16_to_uint8(in16[i]);
                out[j + 1] = downscale_uint16_to_uint8(in16[i + 3]);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out16[j] = in16[i];
                out16[j + 1] = in16[i + 3];
            }
        }
    } else if (inBitDepth == 32) {
        unsigned int *in32 = (unsigned int *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out[j] = downscale(in32[i], maxInSample, 255);
                out[j + 1] = downscale(in32[i + 3], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out16[j] = downscale(in32[i], maxInSample, 65535);
                out16[j + 1] = downscale(in32[i + 3], maxInSample, 65535);            }
        }
    } else {
        unsigned long long *in64 = (unsigned long long *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out[j] = downscale(in64[i], maxInSample, 255);
                out[j + 1] = downscale(in64[i + 3], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 2) {
                out16[j] = downscale(in64[i], maxInSample, 65535);
                out16[j + 1] = downscale(in64[i + 3], maxInSample, 65535);
            }
        }
    }
}

void convert_rgba_to_rgb(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth)
{
    unsigned char maxInSample = (1 << inBitDepth) - 1;
    if (inBitDepth == 8) {
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out[j] = in[i];
                out[j + 1] = in[i + 1];
                out[j + 2] = in[i + 2];
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out16[j] = upscale_uint8_to_uint16(in[i]);
                out16[j + 1] = upscale_uint8_to_uint16(in[i + 1]);
                out16[j + 2] = upscale_uint8_to_uint16(in[i + 2]);
            }
        }
    } else if (inBitDepth == 16) {
        unsigned short *in16 = (unsigned short *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out[j] = downscale_uint16_to_uint8(in16[i]);
                out[j + 1] = downscale_uint16_to_uint8(in16[i + 1]);
                out[j + 2] = downscale_uint16_to_uint8(in16[i + 2]);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out16[j] = in16[i];
                out16[j + 1] = in16[i + 1];
                out16[j + 2] = in16[i + 2];
            }
        }
    } else if (inBitDepth == 32) {
        unsigned int *in32 = (unsigned int *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out[j] = downscale(in32[i], maxInSample, 255);
                out[j + 1] = downscale(in32[i + 1], maxInSample, 255);
                out[j + 2] = downscale(in32[i + 2], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out16[j] = downscale(in32[i], maxInSample, 65535);
                out16[j + 1] = downscale(in32[i + 1], maxInSample, 65535);
                out16[j + 2] = downscale(in32[i + 2], maxInSample, 65535);
            }
        }
    } else {
        unsigned long long *in64 = (unsigned long long *)in;
        if (outBitDepth == 8) {
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out[j] = downscale(in64[i], maxInSample, 255);
                out[j + 1] = downscale(in64[i + 1], maxInSample, 255);
                out[j + 2] = downscale(in64[i + 2], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0, j = 0; i < length; i += 4, j += 3) {
                out16[j] = downscale(in64[i], maxInSample, 65535);
                out16[j + 1] = downscale(in64[i + 1], maxInSample, 65535);
                out16[j + 2] = downscale(in64[i + 2], maxInSample, 65535);
            }
        }
    }
}

void convert_rgba_to_rgba(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char ouBitDepth)
{
    unsigned char maxInSample = (1 << inBitDepth) - 1;
    
    if (inBitDepth == 8) {
        if (ouBitDepth == 8) {
            for (size_t i = 0; i < length; ++i) {
                out[i] = in[i];
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0; i < length; ++i) {
                out16[i] = upscale_uint8_to_uint16(in[i]);
            }
        }
    } else if (inBitDepth == 16) {
        unsigned short *in16 = (unsigned short *)in;
        if (ouBitDepth == 8) {
            for (size_t i = 0; i < length; ++i) {
                out[i] = downscale_uint16_to_uint8(in16[i]);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0; i < length; ++i) {
                out16[i] = in16[i];
            }
        }
    } else if (inBitDepth == 32) {
        unsigned int *in32 = (unsigned int *)in;
        if (ouBitDepth == 8) {
            for (size_t i = 0; i < length; ++i) {
                out[i] = downscale(in32[i], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0; i < length; ++i) {
                out16[i] = downscale(in32[i], maxInSample, 65535);
            }
        }
    } else {
        unsigned long long *in64 = (unsigned long long *)in;
        if (ouBitDepth == 8) {
            for (size_t i = 0; i < length; ++i) {
                out[i] = downscale(in64[i], maxInSample, 255);
            }
        } else {
            unsigned short *out16 = (unsigned short *)out;
            for (size_t i = 0; i < length; ++i) {
                out16[i] = downscale(in64[i], maxInSample, 65535);
            }
        }
    }
}

typedef struct palette {
    const unsigned char *in;
    unsigned char index;
} palette;


KHASH_MAP_INIT_INT(palette, palette)
int convert_rgba_to_index(const unsigned char *in, unsigned char *indexed, unsigned char **palette, unsigned char *paletteCount, size_t length, unsigned char inBitDepth, unsigned char outBitDepth)
{
    khash_t(palette) *palette_table = kh_init(palette);
    unsigned char maxInSample = (1 << inBitDepth) - 1;
    unsigned char *in8 = (unsigned char *)in;
    if (inBitDepth == 16) {
        in8 = malloc(sizeof(char) * length * 4);
        unsigned short *in16 = (unsigned short *)in;
        for (size_t i = 0; i < length; ++i) {
            in8[i] = downscale(in16[i], maxInSample, 255);
        }
    } else if (inBitDepth == 32) {
        in8 = malloc(sizeof(char) * length * 4);
        unsigned int *in32 = (unsigned int *)in;
        for (size_t i = 0; i < length; ++i) {
            in8[i] = downscale(in32[i], maxInSample, 255);
        }
    } else if (inBitDepth == 64) {
        in8 = malloc(sizeof(char) * length * 4);
        unsigned long long *in64 = (unsigned long long *)in;
        for (size_t i = 0; i < length; ++i) {
            in8[i] = downscale(in64[i], maxInSample, 255);
        }
    }
    
    char bit = 8 - outBitDepth;
    for (size_t i = 0, j = 0; i < length; i += 4) {
        
        if (palette_table->size > (1 << outBitDepth)) {
            return -1;
        }
        
        unsigned int key = *(unsigned int *)(in8 + i);
        
        int ret, k;
        
        k = kh_get(palette, palette_table, key);
        int end = kh_end(palette_table);
        
        if (k != end) {
            struct palette palette_value = kh_value(palette_table, k);
            indexed[j] = indexed[j] | (palette_value.index << bit);
        } else {
            unsigned char index = palette_table->size;
            indexed[j] = indexed[j] | (index << bit);
            struct palette palette_value;
            palette_value.in = in8 + i;
            palette_value.index = index;
            k = kh_put(palette, palette_table, key, &ret);
            kh_value(palette_table, k) = palette_value;
        }
        
        bit -= outBitDepth;
        if (bit < 0) {
            bit = 8 - outBitDepth;
            j += 1;
        }
    }
    
    *palette = malloc(palette_table->size * 4);
    
    for (int k = kh_begin(palette_table); k != kh_end(palette_table); ++k)
    {
        if (kh_exist(palette_table, k)) {
            struct palette palette_value = kh_value(palette_table, k);
            
            unsigned char *p = *palette;
            p[palette_value.index * 4] = palette_value.in[0];
            p[palette_value.index * 4 + 1] = palette_value.in[1];
            p[palette_value.index * 4 + 2] = palette_value.in[2];
            p[palette_value.index * 4 + 3] = palette_value.in[3];
        }
    }
    
    *paletteCount = palette_table->size;
    kh_destroy(palette, palette_table);
    
    if (inBitDepth != 8) {
        free(in8);
    }
    
    return 0;
}
