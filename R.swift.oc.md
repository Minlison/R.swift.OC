## 本项目是修改[R.swift](https://github.com/mac-cain13/R.swift) 支持 Objective-C 语言, 生成相应的.h 和.m 文件, 请访问源码地址


### 使用方法
* 1. Check 下本项目
* 2. 运行 rswift.xcodeproj 
* 3. 拷贝项目的 build/Debug 文件夹至你的项目的 .xcodeproj 同级目录下
* 4. 在项目的 buildPhases 中添加下面脚本 语句

```
"$SRCROOT/Rswift/rswift"  "$SRCROOT"

```

* 5. build 你的项目
* 6. 你的项目的 .xcodeproj 同级目录下会生成 Generated 文件夹, 以 Greate groups 的形式引入, 并不要勾选 Copy items if need 选项.
