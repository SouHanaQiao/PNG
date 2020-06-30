//
//  scanline.c
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/16.
//  Copyright © 2019 葬花桥. All rights reserved.
//

#include "scanline.h"
#include <stdlib.h>

static unsigned char paethPredictor(short a, short b, short c) {
    short pa = abs(b - c);
    short pb = abs(a - c);
    short pc = abs(a + b - c - c);
    
    if(pc < pa && pc < pb) return (unsigned char)c;
    else if(pb < pa) return (unsigned char)b;
    else return (unsigned char)a;
}

unsigned defilterScanline(unsigned char* scanline, const unsigned char* reference,
                          size_t stride, unsigned char filterMethod, size_t length) {
    /*
     For PNG filter method 0
     unfilter a PNG image scanline by scanline. when the pixels are smaller than 1 byte,
     the filter works byte per byte (stride = 1)
     reference is the previous unfiltered scanline, recon the result, scanline the current one
     the incoming scanlines do NOT include the filtertype byte, that one is given in the parameter filterType instead
     recon and scanline MAY be the same memory address! reference must be disjoint.
     */
    
    size_t i;
    switch(filterMethod) {
        case 0:
            //            for(i = 0; i != length; ++i) scanline[i] = scanline[i];
            break;
        case 1:
            //            for(i = 0; i != stride; ++i) scanline[i] = scanline[i];
            for(i = stride; i < length; ++i) scanline[i] = scanline[i] + scanline[i - stride];
            break;
        case 2:
            if(reference) {
                for(i = 0; i != length; ++i) scanline[i] = scanline[i] + reference[i];
            } else {
                for(i = 0; i != length; ++i) scanline[i] = scanline[i];
            }
            break;
        case 3:
            if(reference) {
                for(i = 0; i != stride; ++i) scanline[i] = scanline[i] + (reference[i] >> 1);
                for(i = stride; i < length; ++i) scanline[i] = scanline[i] + ((scanline[i - stride] + reference[i]) >> 1);
            } else {
                for(i = 0; i != stride; ++i) scanline[i] = scanline[i];
                for(i = stride; i < length; ++i) scanline[i] = scanline[i] + (scanline[i - stride] >> 1);
            }
            break;
        case 4:
            if(reference) {
                for(i = 0; i != stride; ++i) {
                    scanline[i] = (scanline[i] + reference[i]); /*paethPredictor(0, reference[i], 0) is always reference[i]*/
                }
                for(i = stride; i < length; ++i) {
                    scanline[i] = (scanline[i] + paethPredictor(scanline[i - stride], reference[i], reference[i - stride]));
                }
            } else {
                for(i = 0; i != stride; ++i) {
                    scanline[i] = scanline[i];
                }
                for(i = stride; i < length; ++i) {
                    /*paethPredictor(recon[i - stride], 0, 0) is always recon[i - stride]*/
                    scanline[i] = (scanline[i] + scanline[i - stride]);
                }
            }
            break;
        default: return 36; /*error: unexisting filter type given*/
    }
    return 0;
}


void deinterlaced(DeinterlacedSetting *setting) {
    size_t stride = (setting->bitsPerPixel >> 3) > 1 ? setting->bitsPerPixel >> 3 : 1;
    size_t xOffset = setting->xOffset;
    
    if (setting->bitsPerPixel >= 8) {
        for (int i = 0; i < setting->length; i += stride) {
            size_t index = xOffset * stride + setting->bytesPerRow * setting->yOffset;
            
            for (int j = 0; j != stride; ++j) {
                setting->out[index + j] = setting->scanline[i + j];
            }
            xOffset += setting->incX;
        }
    } else {
        
        for (int i = 0; i < setting->length; ++i) {
            
            size_t index = xOffset * setting->bitsPerPixel + setting->bytesPerRow * setting->yOffset;
            
            unsigned char byte = setting->scanline[i];
            
            for (int j = 0; j != 8; j += setting->bitsPerPixel) {
                unsigned char pixelByte = byte >> (8 - j - setting->bitsPerPixel);
                pixelByte = pixelByte << (8 - j - setting->bitsPerPixel);
                
                byte &= pixelByte;
                
                setting->out[index] |= pixelByte;
            }
            
            xOffset += setting->incX;
        }
    }
}

void apple_png_demultiply(unsigned char *scanline, size_t length, size_t bitsPerPixel) {
    // bitsPerPixel默认大于8, 因为苹果压缩格式为rgba8或rgba16像素
    size_t stride = bitsPerPixel >> 3;
    for (int i = 0; i < length; i += stride) {
        // exchange B and R
        if (stride == 4) {
            unsigned char tmp = scanline[i];
            scanline[i] = scanline[i + 2];
            scanline[i + 2] = tmp;
            
            unsigned char alpha = scanline[i + 3];
            
            if (alpha > 0 && alpha < 255) {
                scanline[i] = scanline[i] * 255 / alpha;
                scanline[i + 1] = scanline[i + 1] * 255 / alpha;
                scanline[i + 2] = scanline[i + 2] * 255 / alpha;
            }
            
        } else if (stride == 8) {
            unsigned short *newCcanline = (unsigned short *)scanline;
            unsigned short tmp = newCcanline[i];
            newCcanline[i] = newCcanline[i + 2];
            newCcanline[i + 2] = tmp;
            
            unsigned short alpha = scanline[i + 3];
            if (alpha > 0 && alpha < 65535) {
                newCcanline[i] = newCcanline[i] * 65535 / alpha;
                newCcanline[i + 1] = newCcanline[i + 1] * 65535 / alpha;
                newCcanline[i + 2] = newCcanline[i + 2] * 65535 / alpha;
            }
        }
    }
}

void apple_png_deinterlaced(DeinterlacedSetting *setting) {
    // bitsPerPixel默认大于8, 因为苹果压缩格式为rgba8或rgba16像素
    size_t stride = setting->bitsPerPixel >> 3;
    size_t xOffset = setting->xOffset;
    
    for (int i = 0; i < setting->length; i += stride) {
        
        size_t index = xOffset * stride + setting->bytesPerRow * setting->yOffset;
        
        // exchange B and R
        if (stride == 4) {
            unsigned char *scanline = (unsigned char *)setting->scanline;
            
            unsigned char alpha = scanline[i + 3];
            
            if (alpha > 0 && alpha < 255) {
                scanline[i] = scanline[i] * 255 / alpha;
                scanline[i + 1] = scanline[i + 1] * 255 / alpha;
                scanline[i + 2] = scanline[i + 2] * 255 / alpha;
            }
            setting->out[index] = scanline[i + 2];
            setting->out[index + 1] = scanline[i + 1];
            setting->out[index + 2] = scanline[i];
            setting->out[index + 3] = scanline[i + 3];
        } else if (stride == 8) {
            unsigned short *scanline = (unsigned short *)setting->scanline;
            
            unsigned short alpha = scanline[i + 3];
            if (alpha > 0 && alpha < 65535) {
                scanline[i] = scanline[i] * 65535 / alpha;
                scanline[i + 1] = scanline[i + 1] * 65535 / alpha;
                scanline[i + 2] = scanline[i + 2] * 65535 / alpha;
            }
            
            unsigned short *out = (unsigned short *)setting->out;
            
            out[index] = scanline[i + 2];
            out[index + 1] = scanline[i + 1];
            out[index + 2] = scanline[i];
            out[index + 3] = scanline[i + 3];
        }
        
        xOffset += setting->incX;
    }
}

void filterScanline(const unsigned char* scanline, unsigned char* out, const unsigned char* prevline,
                           size_t length, size_t stride)
{
    size_t i;
    
    /** None */
    unsigned char none[length + 1];
    size_t none_score = 0;
    none[0] = 0;
    for (i = 0; i != length; ++i) {
        unsigned char v = scanline[i];
        if (none[i] != v) {
            ++none_score;
        }
        none[i + 1] = v;
    }
    
    /** Sub */
    unsigned char sub[length + 1];
    size_t sub_score = 0;
    sub[0] = 1;
    
    for (i = 0; i != stride; ++i) {
        unsigned char v = scanline[i];
        if (sub[i] != v) {
            ++sub_score;
        }
        sub[i + 1] = v;
    }
    
    for (i = stride; i < length; ++i) {
        unsigned char v = scanline[i] - scanline[i - stride];
        if (sub[i] != v) {
            ++sub_score;
        }
        sub[i + 1] = v;
    }
    
    /** Up */
    unsigned char up[length + 1];
    size_t up_score = 0;
    up[0] = 2;
    if(prevline) {
        for(i = 0; i != length; ++i) {
            unsigned char v = scanline[i] - prevline[i];
            if (up[i] != v) {
                ++up_score;
            }
            up[i + 1] = v;
        }
    } else {
        for(i = 0; i != length; ++i) {
            unsigned char v = scanline[i];
            if (up[i] != v) {
                ++up_score;
            }
            up[i + 1] = v;
        }
    }
    
    /** Average */
    unsigned char average[length + 1];
    size_t average_score = 0;
    average[0] = 3;
    
    if(prevline) {
        for(i = 0; i != stride; ++i) {
            unsigned char v = scanline[i] - (prevline[i] >> 1);
            if (average[i] != v) {
                ++average_score;
            }
            
            average[i + 1] = v;
        }
        for(i = stride; i < length; ++i) {
            unsigned char v = scanline[i] - ((scanline[i - stride] + prevline[i]) >> 1);
            if (average[i] != v) {
                ++average_score;
            }
            
            average[i + 1] = v;
        }
    } else {
        for(i = 0; i != stride; ++i) {
            unsigned char v = scanline[i];
            if (average[i] != v) {
                ++average_score;
            }
            
            average[i + 1] = v;
        }
        for(i = stride; i < length; ++i) {
            unsigned char v = scanline[i] - (scanline[i - stride] >> 1);
            if (average[i] != v) {
                ++average_score;
            }
            
            average[i + 1] = v;
        }
    }
    
    /** Paeth */
    unsigned char paeth[length + 1];
    size_t paeth_score = 0;
    paeth[0] = 4;
    if(prevline) {
        /*paethPredictor(0, prevline[i], 0) is always prevline[i]*/
        for(i = 0; i != stride; ++i) {
            unsigned char v = (scanline[i] - prevline[i]);
            if (paeth[i] != v) {
                ++paeth_score;
            }
            paeth[i + 1] = v;
        }
        for(i = stride; i < length; ++i) {
            unsigned char v = (scanline[i] - paethPredictor(scanline[i - stride], prevline[i], prevline[i - stride]));
            if (paeth[i] != v) {
                ++paeth_score;
            }
            paeth[i + 1] = v;
        }
    } else {
        for(i = 0; i != stride; ++i) {
            unsigned char v = scanline[i];
            if (paeth[i] != v) {
                ++paeth_score;
            }
            paeth[i + 1] = v;
        }
        /*paethPredictor(scanline[i - bytewidth], 0, 0) is always scanline[i - bytewidth]*/
        for(i = stride; i < length; ++i) {
            unsigned char v = (scanline[i] - scanline[i - stride]);
            if (paeth[i] != v) {
                ++paeth_score;
            }
            paeth[i + 1] = v;
        }
    }
    
    size_t scores[5] = {none_score, sub_score, up_score, average_score, paeth_score};
    
    unsigned char filter = 0;
    
    size_t min = scores[0];
    
    for (i = 0; i != 5; ++i) {
        if (scores[i] < min) {
            min = scores[i];
            filter = i;
        }
    }
    
    size_t out_length = length + 1;
    
    switch (filter) {
        case 0:
            for(i = 0; i != out_length; ++i) out[i] = none[i];
            break;
        case 1:
            for(i = 0; i != out_length; ++i) out[i] = sub[i];
            break;
        case 2:
            for(i = 0; i != out_length; ++i) out[i] = up[i];
            break;
        case 3:
            for(i = 0; i != out_length; ++i) out[i] = average[i];
            break;
        case 4:
            for(i = 0; i != out_length; ++i) out[i] = paeth[i];
            break;
        default:
            for(i = 0; i != out_length; ++i) out[i] = none[i];
            break;
    }
    
}

void interlacing_none_and_defilter(const unsigned char* input, size_t length, size_t* inputOffset, size_t bitsPerPixel, size_t bytesPerRow, unsigned char* output, size_t* outputOffset) {
    
    unsigned char stride = (bitsPerPixel >> 3) <= 0 ? 1 : (bitsPerPixel >> 3);
    
    while (length - *inputOffset >= bytesPerRow + 1) {
        unsigned char filter = input[*inputOffset];
        *inputOffset += 1;
        const unsigned char* scanline = input + *inputOffset;
        switch (filter) {
            case 0:
                for (size_t i = 0; i < bytesPerRow; ++i) {
                    output[i + *outputOffset] = scanline[i];
                }
                break;
            case 1:
                for(size_t i = 0; i < stride; ++i) {
                    output[i + *outputOffset] = scanline[i];
                }
                
                for(size_t i = stride; i < bytesPerRow; ++i)
                {
                    output[i + *outputOffset] = scanline[i] + output[i + *outputOffset - stride];
                }
                break;
            case 2:
                if(*outputOffset >= bytesPerRow) {
                    for(size_t i = 0; i < bytesPerRow; ++i) output[i + *outputOffset] = scanline[i] + output[i + *outputOffset - bytesPerRow];
                } else {
                    for(size_t i = 0; i < bytesPerRow; ++i) output[i + *outputOffset] = scanline[i];
                }
                break;
            case 3:
                if(*outputOffset >= bytesPerRow) {
                    for (size_t i = 0; i != stride; ++i) {
                        output[i + *outputOffset] = scanline[i] + (output[i + *outputOffset - bytesPerRow] >> 1);
                    }
                    
                    for(size_t i = stride; i < bytesPerRow; ++i) output[i + *outputOffset] = scanline[i] + ((output[i + *outputOffset - stride] + output[i + *outputOffset - bytesPerRow]) >> 1);
                } else {
                    for (size_t i = 0; i != stride; ++i) {
                        output[i + *outputOffset] = scanline[i];
                    }
                   
                    for(size_t i = stride; i < bytesPerRow; ++i) output[i + *outputOffset] = scanline[i] + ((output[i + *outputOffset - stride] + output[i + *outputOffset - bytesPerRow]) >> 1);
                }
                break;
            case 4:
                if(*outputOffset >= bytesPerRow) {
                    for (size_t i = 0; i != stride; ++i) {
                        output[i + *outputOffset] = scanline[i] + output[i + *outputOffset - bytesPerRow];
                    }
                    
                    for (size_t i = stride; i < bytesPerRow; ++i) {
                        output[i + *outputOffset] = (scanline[i] + paethPredictor(output[i + *outputOffset - stride], output[i + *outputOffset - bytesPerRow], output[i + *outputOffset - bytesPerRow - stride]));
                    }
                } else {
                    for (size_t i = 0; i != stride; ++i)
                        output[i + *outputOffset] = scanline[i];
                    
                    for(size_t i = stride; i < bytesPerRow; ++i)
                        /*paethPredictor(recon[i - stride], 0, 0) is always recon[i - stride]*/
                        output[i + *outputOffset] = (scanline[i] + output[i + *outputOffset - stride]);
                    
                }
                break;
            default:
                break;
        }
        
        *outputOffset += bytesPerRow;
        *inputOffset += bytesPerRow;
    }
}

void interlacing_none_and_filter(const unsigned char* input,
           size_t length, size_t bitsPerPixel, size_t bytesPerRow, unsigned char* out)
{
    size_t o = 0;
    unsigned char stride = (bitsPerPixel >> 3) <= 0 ? 1 : (bitsPerPixel >> 3);
//    size_t imageWidth = (bytesPerRow * 8) / bitsPerPixel;
    size_t imageHeight = length / bytesPerRow;
    
    unsigned char scanline[bytesPerRow];
    size_t sc = 0;
    unsigned char prevline[bytesPerRow];
    memset(&prevline, 0, bytesPerRow);
    /** None */
    unsigned char none[bytesPerRow + 1];
    size_t none_score = 0;
    none[0] = 0;
    
    /** Sub */
    unsigned char sub[bytesPerRow + 1];
    size_t sub_score = 0;
    sub[0] = 1;
    
    /** Up */
    unsigned char up[bytesPerRow + 1];
    size_t up_score = 0;
    up[0] = 2;
    
    /** Average */
    unsigned char average[bytesPerRow + 1];
    size_t average_score = 0;
    average[0] = 3;
    
    /** Paeth */
    unsigned char paeth[bytesPerRow + 1];
    size_t paeth_score = 0;
    paeth[0] = 4;
    
    for (size_t y = 0; y != imageHeight; ++y) {
        size_t dy = y * bytesPerRow;
        
        for (sc = 0; sc < bytesPerRow; ++sc) {
            unsigned char v = input[dy + sc];
            scanline[sc] = v;
            
            if (none[sc] != v) {
                ++none_score;
            }
            none[sc + 1] = v;
            
            if (sc < stride) {
                if (sub[sc] != v) {
                    ++none_score;
                }
                sub[sc + 1] = v;
                
                unsigned char v2 = scanline[sc] - (prevline[sc] >> 1);
                if (average[sc] != v2) {
                    ++average_score;
                }
                average[sc + 1] = v2;
                
                unsigned char v3 = (scanline[sc] - prevline[sc]);
                if (paeth[sc] != v3) {
                    ++paeth_score;
                }
                paeth[sc + 1] = v3;
                
            } else {
                unsigned char v = scanline[sc] - scanline[sc - stride];
                if (sub[sc] != v) {
                    ++sub_score;
                }
                sub[sc + 1] = v;
                
                unsigned char av = scanline[sc] - ((scanline[sc - stride] + prevline[sc]) >> 1);
                if (average[sc] != av) {
                    ++average_score;
                }
                
                average[sc + 1] = av;
                
                unsigned char pv = (scanline[sc] - paethPredictor(scanline[sc - stride], prevline[sc], prevline[sc - stride]));
                if (paeth[sc] != pv) {
                    ++paeth_score;
                }
                paeth[sc + 1] = pv;
            }
            
            unsigned char upv = scanline[sc] - prevline[sc];
            if (up[sc] != upv) {
                ++up_score;
            }
            up[sc + 1] = upv;
            
            prevline[sc] = upv;
        }
        
        size_t scores[5] = {none_score, sub_score, up_score, average_score, paeth_score};
        
        unsigned char filter = 0;
        
        size_t min = scores[0];
        
        for (size_t i = 0; i != 5; ++i) {
            if (scores[i] < min) {
                min = scores[i];
                filter = i;
            }
        }
        
        size_t out_length = bytesPerRow + 1;
        
        switch (filter) {
            case 0:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = none[i];
                break;
            case 1:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = sub[i];
                break;
            case 2:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = up[i];
                break;
            case 3:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = average[i];
                break;
            case 4:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = paeth[i];
                break;
            default:
                for(size_t i = 0; i != out_length; ++i, ++o) out[o] = none[i];
                break;
        }
    }
}

void interlacing_adam7_and_filter(const unsigned char* input,
           size_t length, size_t bitsPerPixel, size_t bytesPerRow, unsigned char* out)
{
    size_t i;
    size_t j, o = 0;
    unsigned char startY[7] = {0, 0, 4, 0, 2, 0, 1};
    unsigned char incY[7] = {8, 8, 8, 4, 4, 2, 2};
    unsigned char startX[7] = {0, 4, 0, 2, 0, 1, 0};
    unsigned char incX[7] = {8, 8, 4, 4, 2, 2, 1};
    
    unsigned char stride = (bitsPerPixel >> 3) <= 0 ? 1 : (bitsPerPixel >> 3);
    size_t imageWidth = (bytesPerRow * 8) / bitsPerPixel;
    size_t imageHeight = length / bytesPerRow;
    
    for (i = 0; i < 7; ++i) {
        for (size_t y = startY[i]; y < imageHeight; y += incY[i]) {
            size_t dy = y * bytesPerRow;
            size_t w = (imageWidth - startX[i] + incX[i] - 1) / incX[i];
            size_t scanlineBitCount = w * bitsPerPixel;
            size_t subBytesPerRow = (scanlineBitCount >> 3) + ((scanlineBitCount & 7) == 0 ? 0 : 1);
            
            unsigned char scanline[subBytesPerRow];
            size_t sc = 0;
            unsigned char prevline[subBytesPerRow];
            memset(&prevline, 0, subBytesPerRow);
            /** None */
            unsigned char none[subBytesPerRow + 1];
            size_t none_score = 0;
            none[0] = 0;
            
            /** Sub */
            unsigned char sub[subBytesPerRow + 1];
            size_t sub_score = 0;
            sub[0] = 1;
            
            /** Up */
            unsigned char up[subBytesPerRow + 1];
            size_t up_score = 0;
            up[0] = 2;
            
            /** Average */
            unsigned char average[subBytesPerRow + 1];
            size_t average_score = 0;
            average[0] = 3;
            
            /** Paeth */
            unsigned char paeth[subBytesPerRow + 1];
            size_t paeth_score = 0;
            paeth[0] = 4;
            
            for (size_t x = startX[i]; x < imageWidth; x += incX[i]) {
                for (j = 0; j < stride; ++j, ++sc) {
                    unsigned char v = input[dy + x * stride + j];
                    scanline[sc] = v;
                    
                    if (none[sc] != v) {
                        ++none_score;
                    }
                    none[sc + 1] = v;
                    
                    if (sc < stride) {
                        if (sub[sc] != v) {
                            ++none_score;
                        }
                        sub[sc + 1] = v;
                        
                        unsigned char av = scanline[sc] - (prevline[sc] >> 1);
                        if (average[sc] != av) {
                            ++average_score;
                        }
                        average[sc + 1] = av;
                        
                        unsigned char pv = (scanline[sc] - prevline[sc]);
                        if (paeth[sc] != pv) {
                            ++paeth_score;
                        }
                        paeth[sc + 1] = pv;
                        
                    } else {
                        unsigned char v = scanline[sc] - scanline[sc - stride];
                        if (sub[sc] != v) {
                            ++sub_score;
                        }
                        sub[sc + 1] = v;
                        
                        unsigned char av = scanline[sc] - ((scanline[sc - stride] + prevline[sc]) >> 1);
                        if (average[sc] != av) {
                            ++average_score;
                        }
                        
                        average[sc + 1] = av;
                        
                        unsigned char pv = (scanline[sc] - paethPredictor(scanline[sc - stride], prevline[sc], prevline[sc - stride]));
                        if (paeth[sc] != pv) {
                            ++paeth_score;
                        }
                        paeth[sc + 1] = pv;
                    }
                    
                    unsigned char upv = scanline[sc] - prevline[sc];
                    if (up[sc] != upv) {
                        ++up_score;
                    }
                    up[sc + 1] = upv;
                    
                    prevline[sc] = upv;
                }
            }
            
            size_t scores[5] = {none_score, sub_score, up_score, average_score, paeth_score};
            
            unsigned char filter = 0;
            
            size_t min = scores[0];
            
            for (size_t i = 0; i != 5; ++i) {
                if (scores[i] < min) {
                    min = scores[i];
                    filter = i;
                }
            }
            
            size_t out_length = w * subBytesPerRow + 1;
            
            switch (filter) {
                case 0:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = none[i];
                    break;
                case 1:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = sub[i];
                    break;
                case 2:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = up[i];
                    break;
                case 3:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = average[i];
                    break;
                case 4:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = paeth[i];
                    break;
                default:
                    for(size_t i = 0; i != out_length; ++i, ++o) out[o] = none[i];
                    break;
            }
            
        }
    }
}
