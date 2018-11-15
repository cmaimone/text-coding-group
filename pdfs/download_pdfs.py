import requests


'''This file is an example of downloading a PDF file from the internet with the requests 
   package and saving it locally.  This code would usually be incorporated as part of a larger
   web scraping project.  See the bookreviews directory in this repository for an example, 
   where you'd change how the files you collect are saved to use this method here.
'''


r = requests.get("https://www.rekabet.gov.tr/Karar?kararId=dfbcf00a-7b39-4591-b8ae-a35930295bb6")

with open('courtcase/dfbcf00a-7b39-4591-b8ae-a35930295bb6.pdf', 'wb') as f:
    f.write(r.content)



