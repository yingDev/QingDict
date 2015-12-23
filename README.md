# QingDict
轻量级、实用主义的词典程序 for OS X

![QingDict Icon](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/qingdict.png) 

学习Swift过程中开发

# 获得代码
```bash
  git clone https://github.com/yingDev/QingDict.git
  cd QingDict
  git submodule init && git submodule update
```

# 结构
包含三个Target: 
  - `QingDict`：主程序，处理鼠标取词事件、显示状态栏图标、生词表、偏好设置
  - `QingDict-Result`： 显示执行查词、显示查词结果、与主程序通信；出于减少内存占用的目的，这是一个可独立运行的app，每次执行失去焦点会自动退出
  - `Launch-Helper`(objc)： ServiceManagement实现启动项所需

# 陷阱
  - `QingDict-Result.app`是放在`QingDict.app/Contents/Resources`中的。由于当前Swift运行时没有内置于OS X中，Xcode会拷贝所有swift的dylib到每个app中。这就导致`QingDict-Result.app`和`QingDict.app`都包含独立的一堆dylib，浪费了7MB左右的空间。项目中采取的解决办法是，在Build Phase中把`QingDict-Result.app`中的dylib替换为指向`QingDict.app`中dylib的symlink。
  ```bash
  # 与QingDict.app用到的dylib重复的，替换为symlink
theDir="${TARGET_BUILD_DIR}/${TARGETNAME}.app/Contents/Frameworks"
sourceDir="../../../../Frameworks"
dylibs="libswiftAppKit libswiftCore libswiftCoreData libswiftCoreGraphics libswiftCoreImage libswiftDarwin libswiftDispatch libswiftFoundation libswiftObjectiveC"

for lib in $dylibs
do
    theDylib="$theDir/$lib.dylib"
    rm -f $theDylib
    ln -s $sourceDir/$lib.dylib $theDylib
done
  ```
  - 取词：虽然有Accessibility API，但是OSX中许多程序是不支持此API取词的。本项目中采取了3中手段结合取词：AX、Cmd+C、模拟DragDrop，基本能应对大多数情形。这部分实现在`UserTextSelectionExtractor.swfit`中。
  
# License
`GPL-V3`

# 截图

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/1.gif) 

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/2.gif) 

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/4.gif) 

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/6.gif) 
