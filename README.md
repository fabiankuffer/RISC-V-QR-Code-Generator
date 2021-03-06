# QR-Code Generator

Minimal implementation of a QR code generator in Assembly for RISC-V architectures according to ISO/IEC 18004 "third edition" published 2015-02-01.

## Authors
- [Robin Benzinger](mailto:inf20105@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)
- [Daimon Mayerhöffer](mailto:inf20145@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)
- [Fabian Kuffer](mailto:inf20195@lehre.dhbw-stuttgart.de?subject=[GitHub]%20QRCode)

## Demo Video

[![IMAGE ALT TEXT](http://img.youtube.com/vi/0HXz-XnS0W4/0.jpg)](http://www.youtube.com/watch?v=0HXz-XnS0W4 "RISC-V QR-Code-Generator")

## Description

The QR code generation can be divided into 3 parts. The first part is formatting the data into data words. The next step is to determine the error correction code words. The last step is the conversion of the data into the graphical representation.

The last step of the presentation will take some time. Because the QR code is generated 8 times internally, each time with a different mask. For each mask, the QR code must be gone through 8 more times in order to check the QR code for the individual rules. Finally, the QR code is generated one last time with the mask with the least number of violations.

To simplify the process, data entered is stored in byte mode and all characters are encoded in ASCII. 

Detailed instructions on how to create QR codes can be found at the following links:
- [www.nayuki.io](https://www.nayuki.io/page/creating-a-qr-code-step-by-step)
- [www.thonky.com](https://www.thonky.com/qr-code-tutorial/introduction)

- [format information for QR codes](https://github.com/zxing/zxing/wiki/Barcode-Contents)

### How to run

Execute the file *src/main.asm* in RARS. To display the QR code, the bitmap display must be opened. Set the resolution to 256x256 pixels. Other resolutions can be set in *src/qr_data.asm*. To interact with the programme use the tab "RUN I/O".
## Files

###### **src/main.asm**
------------
 Main file of program
 
###### **src/qr_user-input.asm**
------------
This file processes the input string. Error Correction Level and Version are saved in "qr_data.asm". The Data will be encoded and padded with certain Paddingbytes in the process.

###### **src/qr_generate-error-correction.asm**
------------
This file contains all functions that are needed to create the error correction codewords and zips those codewords with the initial message together and saves them into the final data buffer.
 
###### **src/qr_data.asm**
------------
This file contains all the data needed to create QR codes of any size.
Most tables can be found at the following website:  [www.thonky.com](https://www.thonky.com/qr-code-tutorial/introduction)
 
###### **src/qr_draw.asm**
------------
 This file contains all the steps to graphically display the generated code words in a QR code. It also checks which mask is the best for this QR code.
> Unfortunately, the comments are mostly in German.

###### **src/draw_fun.asm**
------------
This file contains all the functions to simplify drawing on the display.

###### **test/*.asm** and **test/*.json**
------------
All files with this scheme are unit tests.
> Note:
In the graphical representation, not many unit tests can be created, as tests are only useful if the entire image is checked. If the entire memory is inserted into the json file, unfortunately gedit crashes and the json file can't be created.

## Test
Screenshot that shows succedded unittests:
![Screenshot 2021-11-05 004854](https://user-images.githubusercontent.com/83594506/140438059-6cf34454-feb5-4045-8b4e-ed3a01b5f161.png)

## License
MIT License
