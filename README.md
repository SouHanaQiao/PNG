# 根据https://github.com/kelvin13/png
PNG解码添加APNG的解码以及Apple压缩格式的PNG解码, 并将扫描与像素处理改成C函数，以达到了iOS系统解码速度
不使用系统API/imageIO的PNG swift解码与编码项目，可以跨平台使用

==============
- 支持PNG, APNG规范。
- 支持apple优化的CGBi格式
- 支持RGB8, RGB16, RGBA8, RGBA16, V, VA等
- 解码后能转成UIImage
# TODU:
==============
- 未实现APNG编码
