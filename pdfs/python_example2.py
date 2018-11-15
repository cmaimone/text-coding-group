import PyPDF2


# Package documentation: https://pythonhosted.org/PyPDF2/


# open a pdf file; alias the file as pdf (the name of the file object)
with open("example_dissertations_polisci/Weiss_Powerful Patriots.pdf", 'rb') as pdf:

    # Create a reader object to read the file
    pdfReader = PyPDF2.PdfFileReader(pdf)

    # optionally get the number of pages in the file
    print(pdfReader.numPages)

    # aggregate the content of the pages yourself, starting with an empty string
    text = ''

    # here we just get the first 20 pages
    for page in range(20):
        pageObj = pdfReader.getPage(page)
        text += '\n'+pageObj.extractText() # add the results of this page to previous pages

    print(text)
