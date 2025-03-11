### Source Build

* From UE Root Dir, typically /opt/UnrealEngine

```
./Engine/Build/BatchFiles/RunUAT.sh BuildGraph -script=Engine/Build/InstalledEngineBuild.xml -target="Make Installed Build Linux" -set:SignExecutables=true -set:GameConfigurations=Debug;Development;Test;Shipping -set:WithLinux=true -set:WithLinuxArm64=true -set:WithDDC=true -set:ExtraCompileArgs="-bCompileCEF3 -bCompileISPC"

```
