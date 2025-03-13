#!/bin/bash

# Path to Unreal Engine root directory
UE_ROOT="/opt/UnrealEngine"
PLUGINS_DIR="$UE_ROOT/Engine/Plugins"
OUTPUT_DIR="$UE_ROOT/BuiltPlugins"

# Configurations to build
CONFIGS=("Development" "Shipping" "Debug" "DebugGame" "Test")
PLATFORMS=("Linux")
# Add cross-compilation platforms as needed
CROSS_PLATFORMS=("Win64" "Android" "IOS")

# Create output directory
mkdir -p "$OUTPUT_DIR"

# ====== HARDWARE DETECTION ======
echo "======= Detecting hardware configuration ======="
NVIDIA_GPU=$(lspci | grep -i nvidia | grep -i vga)
INTEL_GPU=$(lspci | grep -i intel | grep -i vga)
CPU_CORES=$(nproc)
TOTAL_MEMORY=$(free -g | awk '/^Mem:/{print $2}')

if [ ! -z "$NVIDIA_GPU" ]; then
    echo "NVIDIA GPU detected: $NVIDIA_GPU"
    HAS_NVIDIA=1
    # Check for ray tracing capability
    if nvidia-smi --query-gpu=name --format=csv,noheader | grep -E "RTX|TITAN RTX"; then
        echo "Ray tracing capable GPU detected"
        HAS_RTX=1
    fi
else
    HAS_NVIDIA=0
    HAS_RTX=0
fi

if [ ! -z "$INTEL_GPU" ]; then
    echo "Intel GPU detected: $INTEL_GPU"
    HAS_INTEL=1
else
    HAS_INTEL=0
fi

# ====== AUDIO SYSTEM DETECTION ======
echo "======= Detecting audio configuration ======="
HAS_PIPEWIRE=0
HAS_PULSE=0
HAS_ALSA=0

# Check for Pipewire
if systemctl --user is-active pipewire.service &>/dev/null; then
    echo "Pipewire service detected and running"
    HAS_PIPEWIRE=1
    
    # Check for Pipewire-Pulse
    if systemctl --user is-active pipewire-pulse.service &>/dev/null; then
        echo "Pipewire-Pulse service detected and running"
        HAS_PULSE=1
    fi
elif pidof pulseaudio &>/dev/null; then
    echo "PulseAudio detected and running"
    HAS_PULSE=1
fi

# Check for ALSA
if command -v aplay &>/dev/null; then
    echo "ALSA detected"
    HAS_ALSA=1
fi

# ====== SET ENVIRONMENT VARIABLES FOR OPTIMAL PERFORMANCE ======
echo "======= Setting up environment for optimal performance ======="

# Common environment variables
export SDL_VIDEODRIVER=wayland
export UE_WAYLAND_EGL_FORWARD=1
export SDL_DYNAMIC_API=/usr/lib/libSDL2.so

# Audio environment variables
if [ $HAS_PIPEWIRE -eq 1 ]; then
    # Prefer Pipewire for audio
    export SDL_AUDIODRIVER=pipewire
    export PIPEWIRE_RUNTIME_DIR=/run/user/$(id -u)/pipewire
    export PIPEWIRE_LATENCY="128/48000"  # Lower latency for games
    
    # Pipewire optimizations
    export PIPEWIRE_QUANTUM="1024/48000"  # Better buffer size for games
    export PIPEWIRE_NODE_NAME="UnrealEngine"
    
    if [ $HAS_PULSE -eq 1 ]; then
        # Fallback to pulse compatibility layer if needed
        export PULSE_SERVER=unix:/run/user/$(id -u)/pulse/native
        export PULSE_LATENCY_MSEC=60
    fi
elif [ $HAS_PULSE -eq 1 ]; then
    # Use PulseAudio directly
    export SDL_AUDIODRIVER=pulse
    export PULSE_LATENCY_MSEC=60
elif [ $HAS_ALSA -eq 1 ]; then
    # Fallback to ALSA
    export SDL_AUDIODRIVER=alsa
    export ALSA_DEVICE="default"
fi

# Set higher audio buffer sizes for Unreal Engine to prevent crackling
export UE_AUDIO_BUFFER_SIZE=2048
export UE_AUDIO_QUALITY_LEVEL=2  # Medium quality, better performance

# Vulkan-specific settings
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export ENABLE_VULKAN_RENDERDOC_CAPTURE=1
export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d

# GPU-specific optimizations
if [ $HAS_NVIDIA -eq 1 ]; then
    # NVIDIA optimizations
    export __GL_SHADER_DISK_CACHE=1
    export __GL_SHADER_DISK_CACHE_PATH="/tmp/nvidia-shader-cache"
    export __GL_SHADER_DISK_CACHE_SIZE=1073741824  # 1GB cache
    export __GL_THREADED_OPTIMIZATIONS=1
    export __GL_SYNC_TO_VBLANK=0  # Disable vsync for better performance
    export __VK_ALLOW_VENDOR_EXTENSIONS=1
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export __GL_MaxFramesAllowed=1
    export STAGING_SHARED_MEMORY=1
    
    # Ray tracing optimizations if RTX card
    if [ $HAS_RTX -eq 1 ]; then
        export __NV_RT_ACCELERATION=1
        export NV_USE_UNIFIED_MEMORY=1
    fi
fi

if [ $HAS_INTEL -eq 1 ]; then
    # Intel optimizations
    export MESA_GLSL_CACHE_DISABLE=0
    export MESA_SHADER_CACHE_DIR="/tmp/mesa-shader-cache"
    export INTEL_DEBUG=perf
    
    # For hybrid GPU setups
    if [ $HAS_NVIDIA -eq 1 ]; then
        # Prefer NVIDIA for rendering
        export DRI_PRIME=1
        export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/intel_icd.json
    else
        export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.json
    fi
fi

# Build system optimizations
export UBT_THREADS=$CPU_CORES
export UBT_PARALLEL_EXECUTE_ENABLED=true
# Allocate 80% of RAM to UE build
MEMORY_LIMIT=$(($TOTAL_MEMORY * 80 / 100))
export UBT_MEMORY_LIMIT_MB=$(($MEMORY_LIMIT * 1024))

# ====== SDL2 WITH WAYLAND, X11 AND AUDIO SUPPORT ======
echo "======= Ensuring SDL2 has display and audio support ======="

SDL_SOURCE="$UE_ROOT/Engine/Source/ThirdParty/SDL2"
if [ -d "$SDL_SOURCE" ]; then
    echo "Rebuilding SDL2 with display and audio support..."
    
    # Back up the original directory if not already done
    if [ ! -d "${SDL_SOURCE}_original" ]; then
        cp -r "$SDL_SOURCE" "${SDL_SOURCE}_original"
    fi
    
    # Build SDL2 with all necessary support
    cd "$SDL_SOURCE"
    
    # Check if we should use configure or CMake
    if [ -f "./configure" ]; then
        # Configure with both display server and audio support
        ./configure --enable-video-wayland --enable-video-x11 --enable-video-vulkan \
                    --enable-audio --enable-alsa --enable-pulseaudio --enable-pipewire \
                    --enable-jack
        make clean && make -j$CPU_CORES
        
        echo "SDL2 rebuilt with all display and audio support using configure"
    else
        # Use CMake for better compatibility
        mkdir -p build && cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release \
                -DSDL_WAYLAND=ON \
                -DSDL_X11=ON \
                -DSDL_VULKAN=ON \
                -DSDL_ALSA=ON \
                -DSDL_PULSEAUDIO=ON \
                -DSDL_PIPEWIRE=ON \
                -DSDL_JACK=ON
        make -j$CPU_CORES
        
        # Copy built libraries back to appropriate locations
        cp -f lib/libSDL2*.so* ../lib/
        echo "SDL2 rebuilt with all display and audio support using CMake"
    fi
else
    echo "SDL2 source not found in expected location. Using system SDL2."
    export SDL_DYNAMIC_API=/usr/lib/libSDL2.so
    
    # Check if system SDL2 has the required support
    echo "Checking system SDL2 capabilities..."
    if ! ldd /usr/lib/libSDL2.so | grep -q wayland; then
        echo "Warning: System SDL2 may not have Wayland support"
    fi
    if ! ldd /usr/lib/libSDL2.so | grep -q pulse; then
        echo "Warning: System SDL2 may not have PulseAudio support"
    fi
fi

# Return to UE root
cd "$UE_ROOT"

# ====== ENSURE AUDIO DEPENDENCIES ARE INSTALLED ======
echo "======= Checking audio development libraries ======="

# Create a temporary file to test compile against audio libraries
TEMP_DIR=$(mktemp -d)
cat > $TEMP_DIR/audio_test.c << EOF
#include <stdio.h>
#ifdef __PIPEWIRE__
#include <pipewire/pipewire.h>
#endif
#ifdef __ALSA__
#include <alsa/asoundlib.h>
#endif
#ifdef __PULSE__
#include <pulse/pulseaudio.h>
#endif
int main() { return 0; }
EOF

# Check dependencies with compiler
if gcc -o $TEMP_DIR/test_pw $TEMP_DIR/audio_test.c -D__PIPEWIRE__ -lpipewire-0.3 2>/dev/null; then
    echo "Pipewire development libraries detected"
else
    echo "Warning: Pipewire development libraries missing"
    echo "Consider installing: libpipewire-0.3-dev / pipewire-devel"
fi

if gcc -o $TEMP_DIR/test_alsa $TEMP_DIR/audio_test.c -D__ALSA__ -lasound 2>/dev/null; then
    echo "ALSA development libraries detected"
else
    echo "Warning: ALSA development libraries missing"
    echo "Consider installing: libasound2-dev / alsa-lib-devel"
fi

if gcc -o $TEMP_DIR/test_pulse $TEMP_DIR/audio_test.c -D__PULSE__ -lpulse 2>/dev/null; then
    echo "PulseAudio development libraries detected"
else
    echo "Warning: PulseAudio development libraries missing"
    echo "Consider installing: libpulse-dev / pulseaudio-libs-devel"
fi

# Clean up
rm -rf $TEMP_DIR

# ====== MODIFY UE ENGINE FOR WAYLAND/X11 AND AUDIO SUPPORT ======
LINUX_SPLASH_PATH=$(find "$UE_ROOT/Engine/Source" -name "LinuxPlatformSplash.cpp")
if [ ! -z "$LINUX_SPLASH_PATH" ]; then
    echo "Patching $LINUX_SPLASH_PATH for dynamic display server support"
    if ! grep -q "XDG_SESSION_TYPE" "$LINUX_SPLASH_PATH"; then
        # Create backup
        cp "$LINUX_SPLASH_PATH" "${LINUX_SPLASH_PATH}.bak"
        
        # Add dynamic display server detection
        sed -i '/FLinuxSplashState::Init/,/}/s/\(.*\)SDLWindow = SDL_CreateWindow.*/\1const char* sessionType = getenv("XDG_SESSION_TYPE");\n\1if (sessionType && strcmp(sessionType, "wayland") == 0) {\n\1\tSDL_SetHint(SDL_HINT_VIDEO_DRIVER, "wayland");\n\1}\n\1else {\n\1\tSDL_SetHint(SDL_HINT_VIDEO_DRIVER, "x11");\n\1}\n\1\n\1\/\/ Configure audio\n\1if (getenv("SDL_AUDIODRIVER") == nullptr) {\n\1\tif (system("systemctl --user is-active pipewire.service &>/dev/null") == 0) {\n\1\t\tSDL_SetHint(SDL_HINT_AUDIODRIVER, "pipewire");\n\1\t} else if (system("pidof pulseaudio &>/dev/null") == 0) {\n\1\t\tSDL_SetHint(SDL_HINT_AUDIODRIVER, "pulse");\n\1\t} else {\n\1\t\tSDL_SetHint(SDL_HINT_AUDIODRIVER, "alsa");\n\1\t}\n\1}\n\1SDLWindow = SDL_CreateWindow(/' "$LINUX_SPLASH_PATH"
        
        echo "Patched LinuxPlatformSplash.cpp for dynamic display and audio support"
    else
        echo "LinuxPlatformSplash.cpp already patched"
    fi
fi

# ====== PLUGIN BUILD FUNCTION ======
build_plugin() {
    local plugin_path="$1"
    local config="$2"
    local platform="$3"
    
    local plugin_name=$(basename $(dirname "$plugin_path"))
    echo "Building $plugin_name for $platform ($config)"
    
    # Set platform-specific env vars
    if [ "$platform" == "Android" ]; then
        export ANDROID_HOME=/opt/android-sdk
        export ANDROID_NDK_ROOT=/opt/android-ndk
        export NDKROOT=/opt/android-ndk
    elif [ "$platform" == "IOS" ]; then
        # iOS requires macOS, so this is just a placeholder
        echo "  iOS builds require macOS - skipping"
        return 1
    fi
    
    # Build arguments
    local build_args=("-Plugin=$plugin_path"
                     "-Package=$OUTPUT_DIR/$plugin_name/$platform/$config"
                     "-CreateSubFolder"
                     "-TargetPlatforms=$platform"
                     "-Configuration=$config")
    
    # Add Vulkan/RTX arguments when appropriate
    if [ "$platform" == "Linux" ] || [ "$platform" == "Win64" ]; then
        # Always enable Vulkan
        build_args+=("-EnableVulkan")
        
        # Enable ray tracing if we have an RTX card
        if [ $HAS_RTX -eq 1 ]; then
            build_args+=("-EnableRayTracing")
        fi
        
        # Add audio support
        if [ $HAS_PIPEWIRE -eq 1 ]; then
            build_args+=("-EnablePipewire")
        fi
        if [ $HAS_PULSE -eq 1 ]; then
            build_args+=("-EnablePulseAudio")
        fi
        if [ $HAS_ALSA -eq 1 ]; then
            build_args+=("-EnableALSA")
        fi
    fi
    
    # Execute build
    "$UE_ROOT/Engine/Build/BatchFiles/RunUAT.sh" BuildPlugin "${build_args[@]}"
    
    # Check result
    local build_result=$?
    if [ $build_result -eq 0 ]; then
        echo "  Successfully built $plugin_name for $platform ($config)"
        return 0
    else
        echo "  Failed to build $plugin_name for $platform ($config): Error $build_result"
        return $build_result
    fi
}

# Function to check if a plugin should be built
should_build_plugin() {
    local plugin_dir="$1"
    
    # Skip plugins that are likely editor-only or don't need support
    if [[ "$plugin_dir" == *"Editor"* || "$plugin_dir" == *"PCG"* || "$plugin_dir" == *"Insights"* ]]; then
        return 1
    fi
    
    # Check if uplugin file exists
    local uplugin_file=$(find "$plugin_dir" -name "*.uplugin" -type f | head -1)
    if [ -z "$uplugin_file" ]; then
        return 1
    fi
    
    # Check if plugin is runtime/client capable
    if grep -q "\"CanContainContent\": true" "$uplugin_file" || \
       grep -q "\"CanBeUsedWithUnrealHeaderTool\": true" "$uplugin_file"; then
        return 0
    fi
    
    return 1
}

# ====== BUILD PLUGINS ======
echo "======= Building plugins ======="

# Ask if cross-compilation is desired
read -p "Do you want to build for cross-platform (Win64/Android/iOS)? (y/n) " CROSS_COMPILE
if [[ "$CROSS_COMPILE" == "y" || "$CROSS_COMPILE" == "Y" ]]; then
    ALL_PLATFORMS=("${PLATFORMS[@]}" "${CROSS_PLATFORMS[@]}")
else
    ALL_PLATFORMS=("${PLATFORMS[@]}")
fi

# Set up cross-compilation tools if needed
if [[ "$CROSS_COMPILE" == "y" || "$CROSS_COMPILE" == "Y" ]]; then
    echo "Setting up cross-compilation tools..."
    
    # Check for Windows cross-compile tools
    if [[ " ${ALL_PLATFORMS[@]} " =~ " Win64 " ]]; then
        if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
            echo "Warning: MinGW cross-compiler not found. Windows builds may fail."
        fi
    fi
    
    # Check for Android tools
    if [[ " ${ALL_PLATFORMS[@]} " =~ " Android " ]]; then
        if [ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
            export ANDROID_HOME=/opt/android-sdk
            echo "Set ANDROID_HOME to $ANDROID_HOME"
        fi
        
        if [ -z "$NDKROOT" ] || [ ! -d "$NDKROOT" ]; then
            export NDKROOT=/opt/android-ndk
            export ANDROID_NDK_ROOT=$NDKROOT
            echo "Set NDKROOT to $NDKROOT"
        fi
    fi
fi

# Build all plugins for all platforms
for plugin_dir in "$PLUGINS_DIR"/*; do
    if [ -d "$plugin_dir" ]; then
        plugin_name=$(basename "$plugin_dir")
        
        # Check if we should build this plugin
        if should_build_plugin "$plugin_dir"; then
            echo "Processing plugin: $plugin_name"
            
            # Find uplugin file
            uplugin_file=$(find "$plugin_dir" -name "*.uplugin" -type f | head -1)
            
            # Build for each platform and configuration
            for platform in "${ALL_PLATFORMS[@]}"; do
                for config in "${CONFIGS[@]}"; do
                    build_plugin "$uplugin_file" "$config" "$platform"
                done
            done
        else
            echo "Skipping plugin: $plugin_name (not applicable)"
        fi
    fi
done

echo "Build process complete. Built plugins available in $OUTPUT_DIR"

# Create a report of successful builds
echo "======= Build Summary ======="
echo "Date: $(date)" > "$OUTPUT_DIR/build_report.txt"
echo "Platforms: ${ALL_PLATFORMS[*]}" >> "$OUTPUT_DIR/build_report.txt"
echo "Configurations: ${CONFIGS[*]}" >> "$OUTPUT_DIR/build_report.txt"
echo "Audio: Pipewire=$HAS_PIPEWIRE, PulseAudio=$HAS_PULSE, ALSA=$HAS_ALSA" >> "$OUTPUT_DIR/build_report.txt"
echo "" >> "$OUTPUT_DIR/build_report.txt"
echo "Successfully built plugins:" >> "$OUTPUT_DIR/build_report.txt"

# List successful builds
find "$OUTPUT_DIR" -name "*.uplugin" | sort >> "$OUTPUT_DIR/build_report.txt"

echo "Build report saved to $OUTPUT_DIR/build_report.txt"

