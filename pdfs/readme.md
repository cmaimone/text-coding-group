# Extracting Text from PDFs

## General Considerations


## General Process

### Does your PDF contain text?

There are two main types of PDFs: images and text-based.  The type is determined when the document is scanned or generated.  

The easiest way to tell is to open a PDF in any PDF viewer program: Adobe Acrobat, Preview (Mac), etc.  Make sure the text select tool is on, and try to highlight and copy text you're interested in.  If you can do this, there's already text in your document.  If not, you have an image.  

If you have an image, you need to do an extra step of OCR: optical character recognition.  You need to computer program to essentially look at the files and try to map what's in the image to characters to produce a file with text in it that you can work with.  

### What is the structure/format?

Things to consider

* headers, footers, page numbers
* text in columns 
* data tables
* tables or other features split across pages
* images and image captions
* other special formats: lists, titles, section headers

All of these can create issues in extracting usable text.  A secondary issue is whether you want to try to preserve the structure of the original text in some way - this can be difficult.

For data tables, it's useful to know if there's any redundancy in the table that can be used to check the data: columns with sums, values that should otherwise compute to be equal, etc. 

### Consistency across files

You're probably processing multiple files.  Do they all have the same structure? If not, you'll need to deal with that.

### Extract Text

Depending on what you want from the PDF, you may just want to convert the entire thing to text, then try to process that text later to extract what you want.  

If you just want a few specific pieces of information, then you may want to just try to extract those tidbits.  This latter option works best if the information always appears in the same physical spot on each page, in each file (not just text in the same order).  Then there are methods you can use to target the specific physical space on each page.



## OCR

The likelihood of getting good quality output from OCR depends heavily on the quality of the scan.  Things that affect the quality of the scan include: 

* dpi (dots per inch): how many pixels are used to represent a square inch of the document?  This is also called resolution.  Higher resolution (more dots per inch) equates to more data and greater ability to detect the edges of characters and such, leading to fewer OCR errors
* alignment: the closer a page looks to how it should come out of a printer or look on a computer screen, the better.  This means that it shouldn't be rotated, crooked, etc.  It also means that scans from books with a spine can be problematic, to the extent that the area of the page near the spine is curved, or the edges of the page don't align perfectly with where the edges of the document should be
* font: some fonts are more readable than others.  You don't really have control over this, but it can affect results
* language: if not in English, especially a non-latin script, you'll need different settings at a minimum
* spacing between characters and lines: again, like above, you can't control it, but it does have an impact
* stray marks: stray marks on the page, in the original or from the scanning process, lead to errors
* mixed data: it's easier to read all numbers or all letters.  If you have data in both formats, it's harder
* columns: if text is in multiple columns, it's hard to get data out in a reasonable format.
* vocabulary: docuemnts with a unique set of terms are more difficult because you can't necessarily use standard dictionaries to help you read or interpret words

For poor quality documents, or documents with other characteristics that make them difficult to process, sometimes it's just more efficient to pay people to transcribe them for you.

A useful place to start with OCR: http://guides.library.illinois.edu/c.php?g=347520&p=4121426

## Options for Text Extraction

### ABBYY Fine Reader

Purchase, or available on a computer in the library.

This program will do OCR for you.  It can also be useful for pdfs that already have text in them.

It will also highlight regions, that you can select, deselect, mark as headers and footers, etc.  You can do at least some automation with the program.  

You can convert to excel and other file types in addition to plain text.  This is very useful for data tables, and it can be useful when you want to preserve document formatting as well (when the formatting is providing you with information).

Once you extract the text, you'll still need to process it in another program.

A free alternative, that has some of the functionality, especially around copying data out of tables and into spreadsheets: https://tabula.technology/


### Python

[pdfminer](https://github.com/pdfminer/pdfminer.six) - pdfminer.six is a version for Python 3.  I've used this one.  Tutorial:
* http://stanford.edu/~mgorkove/cgi-bin/rpython_tutorials/Using%20Python%20to%20Convert%20PDFs%20to%20Text%20Files.php

See `python_example.py` for an example using pdfminer

Another option: https://github.com/mstamy2/PyPDF2 (I haven't used this one).  Here are some tutorials that use it:
* https://automatetheboringstuff.com/chapter13/ 
* [http://stanford.edu/~mgorkove/cgi-bin/rpython_tutorials/Using_Python_to_Extract_Tables_From_PDFs.php](http://stanford.edu/~mgorkove/cgi-bin/rpython_tutorials/Using_Python_to_Extract_Tables_From_PDFs.php) (for tables, this uses an API that costs money after 25 pages)

For tables specifically: https://github.com/chezou/tabula-py - wrapper to a Java program (https://tabula.technology/), so it requires setting up Java, which can have it's own challenges.


### R

A good tutorial: https://data.library.virginia.edu/reading-pdf-files-into-r-for-text-mining/ 

In particular, try starting with package pdftools: https://cran.r-project.org/web/packages/pdftools/index.html

Another good walk-through: https://medium.com/@CharlesBordet/how-to-extract-and-clean-data-from-pdf-files-in-r-da11964e252e

There may be other packages.

For tables specifically, tabulizer for tables: https://github.com/ropensci/tabulizer


### Tesseract for OCR

Tesseract is the primary open source OCR program.  There are wrappers for it in R (https://cran.r-project.org/web/packages/tesseract/index.html) and Python (https://pypi.org/project/pytesseract/), and you can run it from the command line: https://github.com/tesseract-ocr/tesseract 

It can take quite a bit of fiddling to get setting correct to work optimally with your particular pdfs.

This tutorial talks about some of the image pre-processing steps that might be necessary: https://medium.freecodecamp.org/getting-started-with-tesseract-part-i-2a6a6b1cf75e