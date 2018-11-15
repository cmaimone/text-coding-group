# example of how to download and save a pdf from a url


getwd()

# make sure all directories exist before trying to write to them; path is relative to your working directory
download.file('https://www.rekabet.gov.tr/Karar?kararId=dfbcf00a-7b39-4591-b8ae-a35930295bb6', 
              'pdfs/courtcase/dfbcf00a-7b39-4591-b8ae-a35930295bb6.pdf', mode="wb")
