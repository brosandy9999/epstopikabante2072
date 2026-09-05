@echo off
title EPS-TOPIK UBT Platform
echo Starting EPS-TOPIK UBT Platform...
start http://localhost:8080
python -m http.server 8080 --directory build/web
