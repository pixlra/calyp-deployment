dir /P /B "ffmpeg" > tmp_filename_ffmpeg
set /p ffmpeg_folder= < tmp_filename_ffmpeg
mv "ffmpeg/%ffmpeg_folder%" ffmpeg_libraries
rm C:\Projects\ffmpeg_libraries\bin\*.exe
