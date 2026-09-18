@echo off
cd /d E:\Test\AtlasChess\App\Mobile
C:\Users\ahmad\develop\flutter\bin\flutter.bat analyze --no-pub > analyze_out.txt 2>&1
echo done > analyze_done.txt
