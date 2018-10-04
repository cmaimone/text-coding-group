from bs4 import BeautifulSoup
import os
import csv
import re


REVIEWDIR = "reviewdownloads"


def extract_pages():
    reviewfiles = [os.path.join(REVIEWDIR, f)
                 for f in os.listdir(REVIEWDIR)
                 if os.path.isfile(os.path.join(REVIEWDIR, f)) and f.endswith(".html")]
    with open("resultdata.csv", "w") as of:
        writer = csv.DictWriter(of, fieldnames=['url','title','author','review','review_author',
                                            'rating','genres','sensuality','published','publisher'])
        writer.writeheader()
        row = {}
        for file in reviewfiles:
            print(file)
            with open(file) as df:
                html = df.read()
            soup = BeautifulSoup(html, "html.parser")

            row['url'] = file.replace("reviewdownloads/", "https://www.rtbookreviews.com/book-review/").\
                replace(".html", "")

            # title
            row['title'] = soup.find("h1", class_="title").get_text().strip()

            # author(s)
            row['author'] = soup.find("div", class_="field-name-field-authors").\
                get_text().replace('Author(s):\xa0', '').strip()

            row['author'] = ", ".join([x.get_text() for x in soup.find("div", class_="field-name-field-authors").\
                                      find("div", class_="field-items").find_all("div")])

            # review text
            row['review'] = ""
            for div in soup.find_all("div", class_="field-name-field-opinion"):
                row['review'] += div.get_text() + "\n"
            for div in soup.find_all("div", class_="field-type-text-with-summary"):
                row['review'] += div.get_text()+"\n"
            row['review'] = row['review'].strip()

            # review author
            row['review_author'] = soup.find("div", class_="field-name-field-reviewed-by").get_text().\
                replace('Reviewed by:\xa0', '').strip()

            # rating
            if 'RT Rating:' in html:
                image = soup.find("img", class_="rt-rating")['src']
                row['rating'] = re.search(r'star-(.+?)-', image).groups(1)[0]

            # genres
            if 'Genre:' in html:
                row['genres'] = soup.find("span", class_="views-label-field-genre").\
                    find_next_sibling().get_text().strip()

            # sensuality
            if 'Sensuality:' in html:
                row['sensuality'] = soup.find("span", class_="views-label-field-sensuality").\
                    find_next_sibling().get_text().strip()

            # published date
            if 'Published:' in html:
                row['published'] = soup.find("span", class_="views-label-field-published").\
                    find_next_sibling().get_text().strip()

            # publisher
            if 'Publisher:' in html:
                row['publisher'] = soup.find("span", class_="views-label-field-publisher").\
                    find_next_sibling().get_text().strip()

            print(row)
            writer.writerow(row)




extract_pages()