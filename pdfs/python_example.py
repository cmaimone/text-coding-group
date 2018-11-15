import io

from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfpage import PDFPage


'''
Gets a plain text version of the supplied pdf
'''
def convert_pdf_to_txt(path, maxpages=0):
    rsrcmgr = PDFResourceManager()  # just create this: you need it

    # Object you're using to read and write your output (you want text, so you're using this); can handle unicode
    retstr = io.StringIO()

    # this is the default codec and a good choice; you'd only need to change this in special cases with
    # foreign languages (most foreign languages in most circumstances will be fine with this)
    codec = 'utf-8'

    # layout parameters: see options at https://github.com/pdfminer/pdfminer.six/blob/master/pdfminer/layout.py
    # You'd change this if you weren't getting good output and wanted to try changing options
    # but mostly I think these are for writing pdfs, not reading them
    laparams = LAParams()

    # creates a converter using the objects initialized above
    device = TextConverter(rsrcmgr, retstr, codec=codec, laparams=laparams)

    # opens the file at the path you supplied
    fp = open(path, 'rb')

    # another object you need
    interpreter = PDFPageInterpreter(rsrcmgr, device)

    # the pages to get; you could modify this to extract certain pages
    # empty will get all
    pagenos = set()

    # process each page according to supplied parameters
    # results are saved via the interpretter into the output object retstr
    for page in PDFPage.get_pages(fp, pagenos, maxpages=maxpages,
                                  check_extractable=True):  # check_extractable checks an option that can be set in a pdf file
        interpreter.process_page(page)

    # actually pull out the value fo the output object;
    # do this here so you can close that object stream before returning from the function
    text = retstr.getvalue()

    fp.close()  # close file
    device.close()  # close converter
    retstr.close()  # close the output stream object
    return text


if __name__ == '__main__':
    text = convert_pdf_to_txt("example_dissertations_polisci/Weiss_Powerful Patriots.pdf", maxpages=20)
    print(text)