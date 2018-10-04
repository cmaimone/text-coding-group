import requests
import time
import os
from bs4 import BeautifulSoup

pageerrors = []
reviewerrors = []
PAGEDIR = "pagedownloads"
REVIEWDIR = "reviewdownloads"
BASEURL = "https://www.rtbookreviews.com"


def page_exists(page):
    return os.path.isfile("{}/{}.html".format(PAGEDIR, page))


def get_page(page):
    print("Downloading page {}".format(page))
    url = "https://www.rtbookreviews.com/book-review?page={}".format(page)
    r = requests.get(url)
    if r.status_code != requests.codes.ok:
        pageerrors.append(page)
        print("Error on page {}: {}".format(page, r.status_code))
        return
    with open("{}/{}.html".format(PAGEDIR, page), 'w') as of:
        of.write(r.text)


def collect_pages():
    for page in range(1282):
        if not page_exists(page):
            get_page(page)
            time.sleep(3)

    ''' if we just had connection issues, we could try again; for other errors, 
    this probably won't resolve the issue because we'll just get the same errors again
    '''
    if len(pageerrors) > 0:
        print("Trying error pages again")
        for page in pageerrors:
            get_page("https://www.rtbookreviews.com/book-review?page={}".format(page))


def extract_links(f):
    with open(f) as df:
        html = df.read()
    soup = BeautifulSoup(html, "html.parser")
    return ["{}{}".format(BASEURL, tag.span.a['href']) for tag in soup.find_all('div', class_="views-field-title")]



def download_review(url):
    print("Downloading {}".format(url))
    r = requests.get(url)
    if r.status_code != requests.codes.ok:
        reviewerrors.append(url)
        print("Error on page {}: {}".format(url, r.status_code))
        return
    with open("{}/{}.html".format(REVIEWDIR, url.split("/")[-1]), 'w') as of:
        of.write(r.text)


def review_exists(url):
    return os.path.isfile("{}/{}.html".format(REVIEWDIR, url.split("/")[-1]))


def collect_reviews():
    pagefiles = [os.path.join(PAGEDIR, f)
                 for f in os.listdir(PAGEDIR)
                 if os.path.isfile(os.path.join(PAGEDIR, f)) and f.endswith(".html")]
    for f in pagefiles:
        links = extract_links(f)
        for link in links:
            if not review_exists(link):
                download_review(link)
                time.sleep(3)
    print("Errors for pages:\n" + "\n".join(reviewerrors))



if __name__ == '__main__':
    collect_pages()
    collect_reviews()