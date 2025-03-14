#!/bin/bash

# Set variables for my audiopulse microphone, headphones, and directory for the recordings
mic="alsa_input.usb-DCMT_Technology_USB_Condenser_Microphone_214b206000000178-00.pro-input-0"
headphones="bluez_output.38_18_4C_24_F1_94.1.monitor"
save_dir="$HOME/recordings"

# Read the file name
read -p "Input your file name: " output_name

# Choose using GUM (https://github.com/charmbracelet/gum) how to record
choice=$(
  gum choose \
    "option 1: video audio(i/o) - main screen" \
    "option 2: video audio(i/o) - secondary screen" \
    "option 3: video audio(i) - main screen" \
    "option 4: video audio(i) - secondary screen" \
    "option 5: video audio (o) - main screen" \
    "option 6: video audio (o) - secondary screen" \
    "option 7: video - main screen" \
    "option 8: video - secondary screen" \
    "option 9: audio only"
)

# Print choice for troubleshooting
# echo "You selected: $choice"

# Quick check if both mic and headphones are on
is_source_available() {
  pactl list sources short | awk '{print $2}' | grep -q "$1"
}

# If there's not on, exit
if ! is_source_available "$mic" || ! is_source_available "$headphones"; then
  echo "Required audio sources not found. Exiting."
  exit 1
fi

# ffmpeg magic depending on the choice of recording
if [[ "$choice" == "option 1: video audio(i/o) - main screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 2560x1440 -framerate 30 -i :0.0+1440,439 \
    -f pulse -i "$mic" \
    -f pulse -i "$headphones" \
    -filter_complex "[1:a]pan=stereo|c0=c0|c1=c0[mic]; [mic][2:a]amerge=inputs=2[a]" \
    -map 0:v -map "[a]" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 2: video audio(i/o) - secondary screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 1440x2560 -framerate 30 -i :0.0+0,0 \
    -f pulse -i "$mic" \
    -f pulse -i "$headphones" \
    -filter_complex "[1:a]pan=stereo|c0=c0|c1=c0[mic]; [mic][2:a]amerge=inputs=2[a]" \
    -map 0:v -map "[a]" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 3: video audio(i) - main screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 2560x1440 -framerate 30 -i :0.0+1440,439 \
    -f pulse -i "$mic" \
    -filter_complex "[1:a]pan=stereo|c0=c0|c1=c0[mic]" \
    -map 0:v -map "[mic]" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 4: video audio(i) - secondary screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 1440x2560 -framerate 30 -i :0.0+0,0 \
    -f pulse -i "$mic" \
    -filter_complex "[1:a]pan=stereo|c0=c0|c1=c0[mic]" \
    -map 0:v -map "[mic]" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 5: video audio (o) - main screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 2560x1440 -framerate 30 -i :0.0+1440,439 \
    -f pulse -i "$headphones" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 6: video audio (o) - secondary screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 1440x2560 -framerate 30 -i :0.0+0,0 \
    -f pulse -i "$headphones" \
    -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 7: video - main screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 2560x1440 -framerate 30 -i :0.0+1440,439 \
    -c:v libx264 -preset ultrafast -crf 18 \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 8: video - secondary screen" ]]; then
  ffmpeg \
    -f x11grab -video_size 1440x2560 -framerate 30 -i :0.0+0,0 \
    -c:v libx264 -preset ultrafast -crf 18 \
    -y "$save_dir/$output_name.mp4"
elif [[ "$choice" == "option 9: audio only" ]]; then
  ffmpeg \
    -f pulse -i "$mic" \
    -f pulse -i "$headphones" \
    -filter_complex "[0:a]pan=stereo|c0=c0|c1=c0[mic]; [mic][1:a]amerge=inputs=2[a]" \
    -map "[a]" \
    -c:a aac -b:a 192k \
    -y "$save_dir/$output_name.mp4"
else
  echo "Invalid choice. Exiting."
fi
