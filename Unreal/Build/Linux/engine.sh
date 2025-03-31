./Engine/Build/BatchFiles/RunUAT.sh BuildGraph -script=Engine/Build/InstalledEngineBuild.xml -target="Make Installed Build Linux" -set:WithLinux=true -set:WithLinuxArm64=true -set:GameConfigurations="Debug;Development;Test;Shipping" -set:WithDDC=true -set:ExtraCompileArgs="-bCompileCEF3 -bCompileISPC" -set:CompileDatasmithPlugins=false -set:WithAndroid=true -set:WithIOS=true -set:WithTVOS=true -set:WithVisionOS=true -set:WithMac=true -set:WithWin64=true -set:AllowParallelExecutor=true 




