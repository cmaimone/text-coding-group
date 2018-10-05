import requests
import time
import os
from bs4 import BeautifulSoup # install beautifulsoup4 with pip

# lists to keep track of errors, if we wanted to
pageerrors = []
reviewerrors = []

# a few constants for convenience
PAGEDIR = "pagedownloads"
REVIEWDIR = "reviewdownloads"
BASEURL = "https://www.rtbookreviews.com"

# check to see if a page listing reviews has already been downloaded
def page_exists(page):
    return os.path.isfile("{}/{}.html".format(PAGEDIR, page))


# download a page listing reviews using the page number
def get_page(page):
    print("Downloading page {}".format(page)) # keep us updated
    url = "https://www.rtbookreviews.com/book-review?page={}".format(page) # url to collect
    r = requests.get(url) # actually get the page
    if r.status_code != requests.codes.ok: # if the status code of the response isn't ok, record it and print info
        pageerrors.append(page)
        print("Error on page {}: {}".format(page, r.status_code))
        return # end this function, don't try to write a file
    # save the text of the result to file
    with open("{}/{}.html".format(PAGEDIR, page), 'w') as of:
        of.write(r.text)

# loop through pages that exist 0-1281 and collect
def collect_pages():
    for page in range(1282):
        if not page_exists(page): # only collect if we haven't already before
            get_page(page)
            time.sleep(3) # pause between requests

    # process error files again (very very basic attempt to handle possible errors)
    ''' if we just had connection issues, we could try again; for other errors, 
    this probably won't resolve the issue because we'll just get the same errors again
    '''
    if len(pageerrors) > 0:
        print("Trying error pages again")
        for page in pageerrors:
            get_page("https://www.rtbookreviews.com/book-review?page={}".format(page))


# get the links to individual book review pages from each result page listing reviews
def extract_links(f):
    with open(f) as df: # open the page from the file
        html = df.read()
    soup = BeautifulSoup(html, "html.parser") # turn into soup we can process
    # below is a list comprehension
    # soup.find_all('div', class_="views-field-title") gets all the div tags with that class
    # we loop through those, and with tag.span.a['href']
    # we get the href value from an a (link) tag inside a span tag inside the div tag we found
    # and then we paste that with our base url for the site to turn a relative link
    # into one we can collect;
    # then return the list of these links
    return ["{}{}".format(BASEURL, tag.span.a['href']) for tag in soup.find_all('div', class_="views-field-title")]


# download an individual book review page
def download_review(url):
    print("Downloading {}".format(url)) # what are we doing
    r = requests.get(url) # get the page
    if r.status_code != requests.codes.ok: # make sure we didn't get a response error
        reviewerrors.append(url)
        print("Error on page {}: {}".format(url, r.status_code))
        return
    # save the file to disk
    with open("{}/{}.html".format(REVIEWDIR, url.split("/")[-1]), 'w') as of:
        of.write(r.text)


# check to see if we have already downloaded a book review file given the url
def review_exists(url):
    return os.path.isfile("{}/{}.html".format(REVIEWDIR, url.split("/")[-1]))


# loop through all of the page files that have been downloaded and collect the individual
# book review pages they link to
def collect_reviews():
    # list comprehension that uses
    # os.listdir(PAGEDIR) to list all of the pages in the directory
    # and put them in a list with the directory name in the front (os.path.join(PAGEDIR, f))
    # if the file is a files (as compared to a directory): os.path.isfile(os.path.join(PAGEDIR, f))
    # and the filename ends with .html (since those are what we saved)
    pagefiles = [os.path.join(PAGEDIR, f)
                 for f in os.listdir(PAGEDIR)
                 if os.path.isfile(os.path.join(PAGEDIR, f)) and f.endswith(".html")]
    # for each of the downloaded page files
    for f in pagefiles:
        links = extract_links(f) # get the links to individual review pages
        for link in links: # for each link on the page
            if not review_exists(link): # if we haven't downloaded it
                download_review(link) # get it
                time.sleep(3) # pause between
    # print out a list of errors we may have encountered
    print("Errors for pages:\n" + "\n".join(reviewerrors))



if __name__ == '__main__':
    # first collect the pages listing all of the reviews
    collect_pages()
    # then collect the individual reviews
    collect_reviews()

    # processing the reviews is in process.py file