import requests
from bs4 import BeautifulSoup

import os
import csv

BASEDOMAIN = "https://www.rtbookreviews.com"

def extract_links(pagenum):
    with open("pagedownloads/{}.html".format(pagenum)) as df:
        listpage = df.read()
    soup = BeautifulSoup(listpage, "html.parser")
    links = []
    for div in soup.find_all("div", class_="views-field-title"):
        links.append(div.span.a['href'])
    return links


def download_page(pagenum):
    r = requests.get("https://www.rtbookreviews.com/book-review?page={}".format(pagenum))
    with open("pagedownloads/{}.html".format(pagenum), 'w') as of:
        of.write(r.text)


def collect_reviews():
    for page in [123]:#range(1282):
        links = extract_links(page)
        for link in links:
            print(r)
            r = requests.get("https://www.rtbookreviews.com{}".format(link))
            #pagename=link.split(link, "/")[-1]
            pagename = link.replace("/book-review/", "")
            with open("reviewdownloads/{}.html".format(pagename), 'w') as of:
                of.write(r.text)


def process_reviews():
    reviewfiles = [os.path.join("reviewdownloads/", f)
                 for f in os.listdir("reviewdownloads/")
                 if os.path.isfile(os.path.join("reviewdownloads/", f)) and f.endswith(".html")]

    with open("results.csv", "w") as of:
        writer = csv.DictWriter(of, fieldnames=['url', 'title'])
        writer.writeheader()
        for rfile in reviewfiles:
            row = {}
            print(rfile)
            with open(rfile) as df:
                rhtml = df.read()
            soup = BeautifulSoup(rhtml, "html.parser")
            row['url'] = rfile
            row['title'] = soup.find("h1", class_="title").get_text()
            writer.writerow(row)




#download_page(123)
#print(extract_links(123))
#collect_reviews()

process_reviews()