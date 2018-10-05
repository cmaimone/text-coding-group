from bs4 import BeautifulSoup
import os
import csv
import re

# where the review files are saved
REVIEWDIR = "reviewdownloads"


def extract_pages():
    # get a list of all of the review files, so we can open then
    reviewfiles = [os.path.join(REVIEWDIR, f)
                 for f in os.listdir(REVIEWDIR)
                 if os.path.isfile(os.path.join(REVIEWDIR, f)) and f.endswith(".html")]
    # create a results files we can write to
    with open("resultdata.csv", "w") as of:
        # use a csv DictWriter where we give it a dict with values and it creates a csv
        # Supply the column names we want to use
        writer = csv.DictWriter(of, fieldnames=['url','title','author','review','review_author',
                                            'rating','genres','sensuality','published','publisher'])
        # write the column names in the first row
        writer.writeheader()
        # loop through each file
        for file in reviewfiles:
            # start with a blank dict for the row
            row = {}
            print(file) # to keep track of what we're processing in case of errors
            # open the review file
            with open(file) as df:
                html = df.read() # read in the source
            soup = BeautifulSoup(html, "html.parser") # make soup (get it into html format we can search)

            # keep the original url
            row['url'] = file.replace("reviewdownloads/", "https://www.rtbookreviews.com/book-review/").\
                replace(".html", "")

            # title: in an h1 take with class title
            row['title'] = soup.find("h1", class_="title").get_text().strip()

            # author(s) - a little tricky because of multiple authors -
            # the command you see on the page isn't actually in the text -
            # so process the individual divs that have the names and join them together
            row['author'] = ", ".join([x.get_text() for x in soup.find("div", class_="field-name-field-authors").\
                                      find("div", class_="field-items").find_all("div")])

            # review text - can be in divs with two different classes, so concatenate these together
            row['review'] = ""
            for div in soup.find_all("div", class_="field-name-field-opinion"):
                row['review'] += div.get_text() + "\n"
            for div in soup.find_all("div", class_="field-type-text-with-summary"):
                row['review'] += div.get_text()+"\n"
            row['review'] = row['review'].strip()

            # review author
            row['review_author'] = soup.find("div", class_="field-name-field-reviewed-by").get_text().\
                replace('Reviewed by:\xa0', '').strip()

            # rating - get from the name of the image file showing the stars
            # but check first to see if the label is in the page text (if it's in this review)
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

            # published date - find the label, then get the "sibling" value in the next div
            if 'Published:' in html:
                row['published'] = soup.find("span", class_="views-label-field-published").\
                    find_next_sibling().get_text().strip()

            # publisher - find the label, then get the "sibling" value in the next div
            if 'Publisher:' in html:
                row['publisher'] = soup.find("span", class_="views-label-field-publisher").\
                    find_next_sibling().get_text().strip()

            print(row)  # just to see what we extracted
            writer.writerow(row)  # write the row to file; it will take care of missing values




extract_pages() # just calling the function above - it doesn't really need to be in a function though