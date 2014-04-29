# ScreenRes-OSX

## Intro
This readme is pretty rough and incomplete.  It will be updated once I get some time.  

This is an OS X Status Bar App to help you easily change display modes for your displays to any supported mode.

I have found it useful for: 
* Quickly changing your display mode when testing during software development.
* Quickly changing modes when your computer is hooked up to a projector or television (in presentations/meetings etc).
* If you have a 'retina display' Mac, you can change your display mode to ridiculously high res modes which your display supports, but are not accessible in the OS X Settings (I will include a screenshot of this).

There are other apps that do this, but I haven't seen one that is free/open source yet.  This is built ontop of code written by one of my friends John Ford, which I have also contributed to a bit.  I haven't included a license in it yet, but feel free to do whatever you want.  I will probably GPL it.  I don't really care.

## Requirements
1. Mac Running OS X 
    * I have only used this on OS X 10.8 and 10.9.  Please let me know if it works or doesn't work on other versions of OS X if you try it.
2. XCode (if you want to build yourself)
3. git (if you want to build yourself)

## Screenshots
![Alt text](http://screenres.colin-mcdonald.com/screenshot.png?raw=true "ScreenRes-OSX Screenshot")

## Binary Download
You can download a zipped, pre-compiled binary from:
http://screenres.colin-mcdonald.com/ScreenRes.zip

The binary is x86_64 only, which should be fine for all newer Macs.

## Build Instructions
These build instructions assume you have git and XCode installed on your Mac.  I may post command line build instructions, or maybe create a makefile for fun so you can just build through the command line.

1. Clone the repository (git clone https://github.com/cmacattack/ScreenRes-OSX.git)
2. Move into project directory on your cloned copy (cd ScreenRes-OSX)
3. Pull in the 'screenresolution' code - it's a git submodule in this case (git submodule init, git submodule update)
4. Open ScreenRes.xcodeproject in ... XCode.
5. Press the 'Build' button...your Done.
    * You can copy ScreenRes.app out of the 'Products' group on the project navigator bar, and place it into your Applications folder...or do with it what you like.
