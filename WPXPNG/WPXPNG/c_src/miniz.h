
size_t tinfl_decompress_mem_to_mem(void *pOut_buf, size_t out_buf_len, const void *pSrc_buf, size_t src_buf_len, int flags);

void loop();

void defilter(unsigned char *scanline, const unsigned char *reference, size_t length, size_t stride);


/**
 对当前扫描行执行去滤波，每扫描一行调用一次

 @param scanline 当前扫描行
 @param reference 上一个扫描行
 @param stride 步长
 @param filterMethod 滤波方法
 @param length 扫描行长度
 @return 0 成功， 36不存在此滤波方法
 */
inline
unsigned defilterScanline(unsigned char* scanline, const unsigned char* reference,
                                 size_t stride, unsigned char filterMethod, size_t length);


/**
 隔行扫描配置
 */
typedef struct DeinterlacedSetting {
    unsigned char* out; /// 图片扫描结果
    const unsigned char *scanline; /// 当前扫描行
    size_t length; /// 当前扫描行长度
    size_t bitsPerPixel; /// 每像素使用的比特位
    size_t bytesPerRow; /// 每行使用的字节数
    size_t xOffset; /// 当前行的列偏移量
    size_t incX; /// 当前ada7 x 增量
    size_t yOffset; /// 当前 adam7 行偏移量
} DeinterlacedSetting;


/**
 adam7扫描函数, 对每张图片按行扫描，每扫描一行调用一次

 @param setting 当前行扫描配置
 */
inline
void deinterlaced(DeinterlacedSetting *setting);


/**
 对苹果压缩格式的PNG图片交换红蓝像素并解预乘，每扫描一行调用一次

 @param scanline 当前扫描行
 @param length 扫描行长度
 @param bitsPerPixel 每像素位数
 */
inline
void apple_png_demultiply(unsigned char *scanline, size_t length, size_t bitsPerPixel);

/**
 对于苹果压缩格式的PNG使用此函数交换红蓝像素并解预乘
 adam7扫描函数, 对每张图片按行扫描，即获取一行扫描一行
 
 @param setting 当前行扫描配置
 */
inline
void apple_png_deinterlaced(DeinterlacedSetting *setting);
