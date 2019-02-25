# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.4

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.4.3/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.4.3/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2

# Utility rule file for ms2-voipdescs-header.

# Include the progress variables for this target.
include src/CMakeFiles/ms2-voipdescs-header.dir/progress.make

src/CMakeFiles/ms2-voipdescs-header:
	cd /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2/src && /usr/local/Cellar/cmake/3.4.3/bin/cmake -DAWK_PROGRAM=/usr/bin/awk -DAWK_SCRIPTS_DIR="/Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2/src/../" -DINPUT_DIR=/Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2/src -DOUTPUT_DIR=/Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2/src -DTYPE=voip -DSOURCE_FILES="audiofilters/alaw.c audiofilters/audiomixer.c audiofilters/chanadapt.c audiofilters/devices.c audiofilters/dtmfgen.c audiofilters/equalizer.c audiofilters/flowcontrol.c audiofilters/g711.c audiofilters/g711.h audiofilters/genericplc.h audiofilters/genericplc.c audiofilters/msgenericplc.c audiofilters/l16.c audiofilters/msfileplayer.c audiofilters/msfilerec.c audiofilters/asyncrw.c audiofilters/asyncrw.h audiofilters/msg722.c audiofilters/msvaddtx.c audiofilters/msvolume.c audiofilters/tonedetector.c audiofilters/ulaw.c audiofilters/waveheader.h crypto/dtls_srtp.c crypto/ms_srtp.c crypto/zrtp.c otherfilters/msrtp.c utils/_kiss_fft_guts.h utils/audiodiff.c utils/dsptools.c utils/g722.h utils/g722_decode.c utils/g722_encode.c utils/h264utils.h utils/h264utils.c utils/kiss_fft.c utils/kiss_fft.h utils/kiss_fftr.c utils/kiss_fftr.h utils/pcap_sender.c utils/pcap_sender.h utils/stream_regulator.c voip/audioconference.c voip/audiostream.c voip/bandwidthcontroller.c voip/bitratecontrol.c voip/bitratedriver.c voip/ice.c voip/mediastream.c voip/msiframerequestslimiter.c voip/msmediaplayer.c voip/msvoip.c voip/private.h voip/qosanalyzer.c voip/qosanalyzer.h voip/qualityindicator.c otherfilters/rfc4103_source.c otherfilters/rfc4103_sink.c otherfilters/msudp.c voip/rfc4103_textstream.c voip/ringstream.c voip/stun.c audiofilters/aac-eld.c audiofilters/gsm.c audiofilters/msopus.c audiofilters/msresample.c audiofilters/msspeex.c audiofilters/speexec.c utils/bits_rw.c videofilters/extdisplay.c videofilters/mire.c videofilters/nowebcam.c videofilters/pixconv.c videofilters/sizeconv.c voip/layouts.c voip/layouts.h voip/msvideo.c voip/msvideo_neon.c voip/msvideo_neon.h voip/nowebcam.h voip/rfc2429.h voip/rfc3984.c voip/videostarter.c voip/videostream.c voip/video_preset_high_fps.c videofilters/turbojpegnowebcam.c utils/opengl_functions.c utils/opengl_functions.h utils/opengles_display.c utils/opengles_display.h utils/shader_util.c utils/shader_util.h voip/scaler.c videofilters/videotoolbox.c videofilters/turbojpegwriter.c videofilters/vp8.c voip/vp8rtpfmt.c voip/vp8rtpfmt.h videofilters/mkv.c utils/mkv_reader.c voip/rfc2429.h voip/rfc3984.c audiofilters/aqsnd.m audiofilters/msiounit.m videofilters/iosdisplay.m videofilters/ioscapture.m voip/ioshardware.m" -P /Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2/src/generate_descs_header.cmake

ms2-voipdescs-header: src/CMakeFiles/ms2-voipdescs-header
ms2-voipdescs-header: src/CMakeFiles/ms2-voipdescs-header.dir/build.make

.PHONY : ms2-voipdescs-header

# Rule to build all files generated by this target.
src/CMakeFiles/ms2-voipdescs-header.dir/build: ms2-voipdescs-header

.PHONY : src/CMakeFiles/ms2-voipdescs-header.dir/build

src/CMakeFiles/ms2-voipdescs-header.dir/clean:
	cd /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2/src && $(CMAKE_COMMAND) -P CMakeFiles/ms2-voipdescs-header.dir/cmake_clean.cmake
.PHONY : src/CMakeFiles/ms2-voipdescs-header.dir/clean

src/CMakeFiles/ms2-voipdescs-header.dir/depend:
	cd /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2 /Users/eicaptain/Desktop/linphone-iphone/submodules/linphone/mediastreamer2/src /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2 /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2/src /Users/eicaptain/Desktop/linphone-iphone/WORK/ios-x86_64/Build/ms2/src/CMakeFiles/ms2-voipdescs-header.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : src/CMakeFiles/ms2-voipdescs-header.dir/depend

