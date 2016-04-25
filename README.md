# QingDict
轻量级、实用主义的词典程序 for OS X

![QingDict Icon](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/qingdict.png) 

开发QingDict是基于以下一些想法：
  - 词典是为了帮助用户记住单词，而不是让用户反复查询同一个单词
  - 工具程序不应该分散用户的注意力
  - 以“实用”为目标，不拘泥于形式

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

# 截图

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/1.gif) 
![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/2.gif) 

![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/6.gif) 
![QingDict Demo](https://raw.githubusercontent.com/yingDev/QingDict/master/.readmeImages/4.gif) 


# 有趣的关注点

* 取词<br/>
  虽然有Accessibility API，但是OSX中许多程序是不支持此API取词的。本项目中采取了3中手段结合取词：AX、Cmd+C、模拟DragDrop，基本能应对大多数情形。这部分实现在`UserTextSelectionExtractor.swfit`中。

* 进程间通信<br/>
  主程序与结果显示程序间用到了两种简单的IPC机制：命令行参数 和 `NSDistributedNotification`。前者用于传递查询的单词和选项等；后者主要作为“添加到生词表”的API。

* 可滑动删除条目的NSTableRowView<br/>
  ```Swift
  //这个类通过派生NSTableRowView, 处理一些鼠标事件、绘制逻辑，从而可以实现生词表“滑动删除条目”功能
  class WordbookRowView : NSTableRowView ...
  ```

* NSStatusItem Hacking<br/>
  有很多OSX程序拥有菜单栏图标(NSStatusItem)，其中一些有通过自定义窗口来实现的“弹出菜单”，这类实现往往有个问题，那就是Status Item的高亮状态，与系统不匹配。
  ```Swift
  //在 AppDelegate 的 createStatusItem() 方法中，通过这个方法拦截鼠标左键事件，阻止StatusItem被单击而引发系统默认行为，然后手动设置其高亮状态
  NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.LeftMouseDownMask) ...
  ```


* Swift dylibs<br/>
  `QingDict-Result.app`是放在`QingDict.app/Contents/Resources`中的。由于当前Swift运行时没有内置于OS X中，Xcode会拷贝所有swift的dylib到每个app中。这就导致`QingDict-Result.app`和`QingDict.app`都包含独立的一堆dylib，浪费了7MB左右的空间。项目中采取的解决办法是，在Build Phase中把`QingDict-Result.app`中的dylib替换为指向`QingDict.app`中dylib的symlink。
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
  
# License
`GPL-V3`
