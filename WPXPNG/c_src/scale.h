//
//  scale.h
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/13.
//  Copyright © 2019 葬花桥. All rights reserved.
//

#ifndef scale_h
#define scale_h


#include <stdio.h>

/**
 将索引色转为RGBA色

 @param in 索引输入指针
 @param out rgba输出指针
 @param length 输入长度
 @param inBitDepth 输入位深 1/2/4/8
 @param outBitDepth 输出位深 8/16/32/64
 @param palette 调色版指针, rgba8
 */
inline void convert_index_to_rgba(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth, const unsigned char *palette);

inline void convert_index_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette);


inline void convert_index8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette);

inline void convert_v_to_rgba(const unsigned char *in, unsigned char *out, size_t length, size_t type, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);

inline void convert_v8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_v16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_va8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length);
inline void convert_va8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length);
inline void convert_va8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length);
inline void convert_va8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length);

inline void convert_va16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length);
inline void convert_va16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length);
inline void convert_va16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length);
inline void convert_va16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length);

inline void convert_rgb8_to_rgba8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_rgb16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_rgba16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_rgba8_to_rgba16(const unsigned char *in, unsigned short *out, size_t length);
inline void convert_rgba8_to_rgba32(const unsigned char *in, unsigned int *out, size_t length);
inline void convert_rgba8_to_rgba64(const unsigned char *in, unsigned long long *out, size_t length);

inline void convert_rgba16_to_rgba8(const unsigned short *in, unsigned char *out, size_t length);
inline void convert_rgba16_to_rgba32(const unsigned short *in, unsigned int *out, size_t length);
inline void convert_rgba16_to_rgba64(const unsigned short *in, unsigned long long *out, size_t length);


inline void convert_index_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette);

inline void convert_index8_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned char *palette);
inline void convert_index8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned char *palette);

inline void convert_v_to_va8(const unsigned char *in, unsigned char *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_va16(const unsigned char *in, unsigned short *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_va32(const unsigned char *in, unsigned int *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);
inline void convert_v_to_va64(const unsigned char *in, unsigned long long *out, size_t length, unsigned char bitDepth, const unsigned short *chromaKey);

inline void convert_v8_to_va8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_va16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_va32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_v8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_v16_to_va8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_va16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_va32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_v16_to_va64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_va8_to_va16(const unsigned char *in, unsigned short *out, size_t length);
inline void convert_va8_to_va32(const unsigned char *in, unsigned int *out, size_t length);
inline void convert_va8_to_va64(const unsigned char *in, unsigned long long *out, size_t length);

inline void convert_va16_to_va8(const unsigned short *in, unsigned char *out, size_t length);
inline void convert_va16_to_va32(const unsigned short *in, unsigned int *out, size_t length);
inline void convert_va16_to_va64(const unsigned short *in, unsigned long long *out, size_t length);

inline void convert_rgb8_to_va8(const unsigned char *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_va16(const unsigned char *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_va32(const unsigned char *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb8_to_va64(const unsigned char *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_rgb16_to_va8(const unsigned short *in, unsigned char *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_va16(const unsigned short *in, unsigned short *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_va32(const unsigned short *in, unsigned int *out, size_t length, const unsigned short *chromaKey);
inline void convert_rgb16_to_va64(const unsigned short *in, unsigned long long *out, size_t length, const unsigned short *chromaKey);

inline void convert_rgba8_to_va8(const unsigned char *in, unsigned char *out, size_t length);
inline void convert_rgba8_to_va16(const unsigned char *in, unsigned short *out, size_t length);
inline void convert_rgba8_to_va32(const unsigned char *in, unsigned int *out, size_t length);
inline void convert_rgba8_to_va64(const unsigned char *in, unsigned long long *out, size_t length);

inline void convert_rgba16_to_va8(const unsigned short *in, unsigned char *out, size_t length);
inline void convert_rgba16_to_va16(const unsigned short *in, unsigned short *out, size_t length);
inline void convert_rgba16_to_va32(const unsigned short *in, unsigned int *out, size_t length);
inline void convert_rgba16_to_va64(const unsigned short *in, unsigned long long *out, size_t length);

/**
 将RGBA色转成V
 
 @param in rgba输入指针
 @param out v输出指针
 @param length 输入长度
 @param inBitDepth 输入rgba位深 8/16/32/64
 @param outBitDepth 输出v位深 1/2/4/8/16
 */
inline void convert_rgba_to_v(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth);

/**
 将RGBA色转成VA
 
 @param in rgba输入指针
 @param out va输出指针
 @param length 输入长度
 @param inBitDepth 输入rgba位深 8/16/32/64
 @param outBitDepth 输出va位深 8/16
 */
inline void convert_rgba_to_va(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth);

/**
 将RGBA色转成RGB
 
 @param in rgba输入指针
 @param out rgb输出指针
 @param length 输入长度
 @param inBitDepth 输入rgba位深 8/16/32/64
 @param outBitDepth 输出rgb位深 8/16/32/64
 */
inline void convert_rgba_to_rgb(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth);
/**
 将RGBA色转成RGBA

 @param in rgba输入指针
 @param out rgba输出指针
 @param length 输入长度
 @param inBitDepth 输入rgba位深 8/16/32/64
 @param outBitDepth 输出rgba位深 8/16/32/64
 */
inline void convert_rgba_to_rgba(const unsigned char *in, unsigned char *out, size_t length, unsigned char inBitDepth, unsigned char outBitDepth);


/**
 将RGBA色转成索引色

 @param in rgba输入指针
 @param indexed 输出的索引指针
 @param palette 调色版二维指针
 @param paletteCount 调色版颜色数
 @param length 输入长度
 @param inBitDepth 输入rgba位深 8/16/32/64
 @param outBitDepth 输出索引位深 1/2/4/8
 @return 0 成功 或者 -1 调色版溢出
 */
inline int convert_rgba_to_index(const unsigned char *in, unsigned char *indexed, unsigned char **palette, unsigned char *paletteCount, size_t length, unsigned char inBitDepth, unsigned char outBitDepth);

#endif /* scale_h */
