# This is a re-writing of the Python code; may not quite be the most R way to do this

# I need this line in my code because my RStudio project was at a level higher.
# you probably don't need this: use RStudio projects to manage paths
#setwd("bookreviews")

library(readr)
library(httr)
library(rvest)
library(glue)
library(stringr)
library(dplyr)

# I set some values as constants for convenience.
# Create the two subdirectories manually before you try to write files to them
PAGEDIR <- "pagedownloads"
REVIEWDIR <- "reviewdownloads"
BASEURL <- "https://www.rtbookreviews.com"


# check if a page of book review results has already been saved in the directory
page_exists <- function(page) {
  file.exists(glue("{PAGEDIR}/{page}.html"))
}

# download a page of book review results and save to file
get_page <- function(page) {
  print(glue("Downloading page {page}")) # keep us updated of progress
  # glue below is a way to concatenate a variable into a string
  url <- glue("https://www.rtbookreviews.com/book-review?page={page}")
  # get the source of the page from the url
  r <- GET(url)
  # if the status code indicates an error, stop the process and throw an error
  stop_for_status(r)
  # write to file the content of the response from GET
  write(content(r, "text"), file=glue("{PAGEDIR}/{page}.html"))
}

# loop through all of the pages of book reviews and collect each one
collect_pages <- function() {
  for (page in 0:1281) {
    # check to see if I've already downloaded the page; only collect what wasn't downloaded before
    if (!page_exists(page)) {
      get_page(page)
      # make sure to take a break to be respectful of the server
      Sys.sleep(3)
    }
  }
}


# get the links to individual book review pages out of a file (from pagedownloads)
extract_links <- function(f) {
  # read in the file as a html object that rvest can work with
  html_contents <- read_html(f)
  # using pipes (%>%) get the html nodes (tags) that have class .views-field-title
  # and get the a (link) tags from inside those nodes 
  # and get the href (link) attribute out of those a tags
  html_contents %>% html_nodes(".views-field-title") %>%
    html_nodes("a") %>%
    html_attr("href") 
}

# download and save an individual book review page
download_review <- function(url) {
  print(glue("Downloading {url}")) # keep us updated
  # get the page
  r <- GET(url)
  # cause an error if there's an error when collecting
  stop_for_status(r)
  # get the last part of the url of the book review to use as the filename - 
  # doing so by just removing the common part of the URL
  f <- str_remove(url, paste0(BASEURL, "/book-review/"))
  # write the content of the response to file
  write(content(r, "text"), file=glue("{REVIEWDIR}/{f}.html"))
}

# check to see if a particular review has already been downloaded
review_exists <- function(url) {
  # get the name of the review file from the url
  urlparts <- strsplit(url, "/")
  # check if the file already exists in the directory
  file.exists(glue("{REVIEWDIR}/{urlparts[length(urlparts)]}.html"))
}

# loop through and collect all of the reviews by extracting links from 
# the page files that have already been downloaded
collect_reviews <- function() {
  # look in the directory of page results and find what was downloaded
  pagefiles <- list.files(path=PAGEDIR, pattern="html$", full.names=TRUE)
  for (f in pagefiles) {
    print(f) # which page are we processing
    links <- extract_links(f)
    for (link in links) { # collect from all of the links on the page
      if (!review_exists(link)) { # only if the file doesn't already exist
        download_review(glue("{BASEURL}{link}"))
        Sys.sleep(3) # sleep between requests
      }
    }
  }
}

# get the information we want out of the book review pages
extract_pages <- function() {
  # get a list of all of the book review files downloaded
  reviewfiles <- list.files(path=REVIEWDIR, pattern="html$", full.names = TRUE)
  # make a data frame to store the results in,
  # one row per downloaded file
  results <- data.frame(url=rep(NA, length(reviewfiles)), title=NA, author=NA,
                        review=NA, review_author=NA, rating=NA, genres=NA, 
                        sensuality=NA, published=NA, publisher=NA)
  # loop through downloaded files
  for (idx in 1:length(reviewfiles)) {
    print(reviewfiles[idx]) # informational
    html_content <- read_html(reviewfiles[idx]) # read from file into an object we can work with
    
    # reconstruct the url we got this from
    results[idx, "url"] <- str_replace(reviewfiles[idx], "reviewdownloads2/", 
                                       "https://www.rtbookreviews.com/book-review/") %>%
      str_replace("\\.html", "")
    
    # title is in an h1 tag with class title
    results[idx, "title"] <- html_content %>% html_node("h1.title") %>%
      html_text(trim=TRUE) 
    
    # author is tricky in cases where there are multiple authors
    # find the relevant chunk on the page, then the items in it, 
    # then join those back together with commas (which show on the page but aren't in the text)
    results[idx, "author"] <- html_content %>% 
      html_nodes("div.field-name-field-authors div.field-items div.field-item") %>%
      html_text(trim=TRUE) %>% paste(collapse=", ")
    
    # get the review itself in two parts, because there's sometimes a paragraph
    # that appears in bold, then one in normal font
    # and these are in divs with different classes
    results[idx, "review"] <- html_content %>%
      html_nodes("div.field-name-field-opinion") %>%
      html_text(trim=TRUE) %>% paste(collapse="\n")
    results[idx, "review"] <- html_content %>%
      html_nodes("div.field-type-text-with-summary") %>%
      html_text(trim=TRUE) %>% paste(collapse="\n") %>% 
      append(results[idx, "review"], 0) %>% paste(collapse="\n")
    
    # get the review author
    results[idx, "review_author"] <- html_content %>% 
      html_node("div.field-name-field-reviewed-by div.field-items") %>%
      html_text(trim=TRUE)
    
    # for rating, get the numeric rating from the image filename
    results[idx, "rating"] <- html_content %>% 
      html_node("img.rt-rating") %>%
      html_attr("src") %>% str_match(pattern="star-(.+?)-") %>% .[,2]
    
    # list of genres
    results[idx, "genres"] <- html_content %>% 
      html_node("div.views-field-field-genre div.field-content") %>%
      html_text(trim=TRUE)
    
    # sensuality rating
    results[idx, "sensuality"] <- html_content %>% 
      html_node("div.views-field-field-sensuality div.field-content") %>%
      html_text(trim=TRUE)
    
    # publisher and publish date are in a div together;
    # sometimes only one or the other is there;
    # so include some logic to figure out what's what
    pubs <- html_content %>% 
      html_nodes("div.amazon-details div.views-field") %>%
      html_text(trim=TRUE)
    if(length(pubs) > 0) {
      if (str_detect(pubs[1], "Published:")) { # look for label to know what we have
        results[idx, "published"] <- str_replace(pubs[1], "Published:\\s+", "")
        if (length(pubs) == 2) {
          results[idx, "publisher"] <- str_replace(pubs[2], "Publisher:\\s+", "")
        }
      } else if (str_detect(pubs[1], "Publisher:")) {
        results[idx, "publisher"] <- str_replace(pubs[1], "Publisher:\\s+", "")
      }
    }
  }
  # write our data frame to file
  write_csv(results, "resultdata.csv")
  # and return the data frame in case we want to use it
  results
}


# first collect all of the 1282 pages that list the book reviews
collect_pages()
# the collect the individual review files
collect_reviews()
# then extract the information from each review file
results <- extract_pages()
# and look at our resulting data frame
View(results)


