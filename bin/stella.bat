@echo off

rem Check for funkiness when called from another batch script.
rem We want FULL_PATH to contain the full path to the stella bin directory. 
IF EXIST "%~dp0stella.bat" (set FULL_PATH=%~dp0) ELSE (set FULL_PATH=%~dp$PATH:0)

rem Check for JRuby, otherwise use Ruby.
rem We want EXECUTABLE to contain either "jruby" or "ruby"
IF EXIST "%JRUBY_HOME%" (set EXECUTABLE=jruby) ELSE (set EXECUTABLE=ruby)

rem Call the Ruby script, passing it all the arguments.
@%EXECUTABLE% %FULL_PATH%stella %*
