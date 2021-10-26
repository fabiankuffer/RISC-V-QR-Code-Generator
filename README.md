# QR-Code Generator

Minimal implementation of a QR code generator in Assembly for RISC-V architectures according to ISO/IEC 18004 "third edition" published 2015-02-01.

## Authors
- [Robin Benzinger](mailto:inf20105@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)
- [Daimon Mayerhöffer](mailto:inf20145@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)
- [Fabian Kuffer](mailto:inf20195@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)

## Demo Video

[![IMAGE ALT TEXT](http://img.youtube.com/vi/-h3eH4ubuno/0.jpg)](http://www.youtube.com/watch?v=-h3eH4ubuno "Video Title")

## Description

The QR code generation can be divided into 3 parts. The first part is formatting the data into data words. The next step is to determine the error correction code words. The last step is the conversion of the data into the graphical representation.

The last step of the presentation will take some time. Because the QR code is generated 8 times internally, each time with a different mask. For each mask, the QR code must be gone through 8 more times in order to check the QR code for the individual rules. Finally, the QR code is generated one last time with the mask with the least number of violations.

To simplify the process, data entered is stored in byte mode and all characters are encoded in ASCII. 

Detailed instructions on how to create QR codes can be found at the following links:
- [www.nayuki.io](https://www.nayuki.io/page/creating-a-qr-code-step-by-step)
- [www.thonky.com](https://www.thonky.com/qr-code-tutorial/introduction)

### How to run

Execute the file *src/main.asm* in RARS. To display the QR code, the bitmap display must be opened. Set the resolution to 256x256 pixels. Other resolutions can be set in *src/qr_data.asm*. For input, the Keyboard and Display MMIO Simulator must be opened.

## Files
######**src/main.asm**
------------
 Main file of program
 
######**src/qr_data.asm**
------------
This file contains all the data needed to create QR codes of any size.
Most tables can be found at the following website:  [www.thonky.com](https://www.thonky.com/qr-code-tutorial/introduction)
 
 ######**src/qr_draw.asm**
------------
 This file contains all the steps to graphically display the generated code words in a QR code. It also checks which mask is the best for this QR code.
> Unfortunately, the comments are mostly in German.

 ######**src/draw_fun.asm**
------------
This file contains all the functions to simplify drawing on the display.

 ######**test/*.asm**
------------
All files with this scheme are unit tests.

## Test
Screenshot that shows succedded (unit) tests 

## License
MIT License
