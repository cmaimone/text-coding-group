# This is a re-writing of the Python code; may not quite be the most R way to do this

setwd("bookreviews")

library(readr)
library(httr)
library(rvest)
library(glue)
library(stringr)
library(dplyr)


PAGEDIR = "pagedownloads"
REVIEWDIR = "reviewdownloads"
BASEURL = "https://www.rtbookreviews.com"


page_exists <- function(page) {
  file.exists(glue("{PAGEDIR}/{page}.html"))
}

get_page <- function(page) {
  print(glue("Downloading page {page}"))
  url <- glue("https://www.rtbookreviews.com/book-review?page={page}")
  r <- GET(url)
  stop_for_status(r)
  write(content(r, "text"), file=glue("{PAGEDIR}/{page}.html"))
}


collect_pages <- function() {
  for (page in 0:1281) {
    if (!page_exists(page)) {
      get_page(page)
      Sys.sleep(3)
    }
  }
}

extract_links <- function(f) {
  html_contents <- read_html(f)
  html_contents %>% html_nodes(".views-field-title") %>%
    html_nodes("a") %>%
    html_attr("href") 
}


download_review <- function(url) {
  print(glue("Downloading {url}"))
  r <- GET(url)
  stop_for_status(r)
  urlparts <- strsplit(url, "/")[[1]]
  f <- urlparts[length(urlparts)]
  write(content(r, "text"), file=glue("{REVIEWDIR}/{f}.html"))
}


review_exists <- function(url) {
  urlparts <- strsplit(url, "/")
  file.exists(glue("{REVIEWDIR}/{urlparts[length(urlparts)]}.html"))
}


collect_reviews <- function() {
  pagefiles <- list.files(path=PAGEDIR, pattern="html$", full.names=TRUE)
  for (f in pagefiles) {
    links <- extract_links(f)
  }
  for (link in links) {
    if (!review_exists(link)) {
      download_review(glue("{BASEURL}{link}"))
      Sys.sleep(3)
    }
  }
}


extract_pages <- function() {
  reviewfiles <- list.files(path=REVIEWDIR, pattern="html$", full.names = TRUE)
  results <- data.frame(url=rep(NA, length(reviewfiles)), title=NA, author=NA,
                        review=NA, review_author=NA, rating=NA, genres=NA, 
                        sensuality=NA, published=NA, publisher=NA)
  for (idx in 1:length(reviewfiles)) {
    print(reviewfiles[idx])
    html_content <- read_html(reviewfiles[idx])
    results[idx, "url"] <- str_replace(reviewfiles[idx], "reviewdownloads2/", 
                                       "https://www.rtbookreviews.com/book-review/") %>%
      str_replace("\\.html", "")
    results[idx, "title"] <- html_content %>% html_node("h1.title") %>%
      html_text(trim=TRUE) 
    results[idx, "author"] <- html_content %>% 
      html_nodes("div.field-name-field-authors div.field-items div.field-item") %>%
      html_text(trim=TRUE) %>% paste(collapse=", ")
    results[idx, "review"] <- html_content %>%
      html_nodes("div.field-name-field-opinion") %>%
      html_text(trim=TRUE) %>% paste(collapse="\n")
    results[idx, "review"] <- html_content %>%
      html_nodes("div.field-type-text-with-summary") %>%
      html_text(trim=TRUE) %>% paste(collapse="\n") %>% 
      append(results[idx, "review"], 0) %>% paste(collapse="\n")
    results[idx, "review_author"] <- html_content %>% 
      html_node("div.field-name-field-reviewed-by div.field-items") %>%
      html_text(trim=TRUE)
    results[idx, "rating"] <- html_content %>% 
      html_node("img.rt-rating") %>%
      html_attr("src") %>% str_match(pattern="star-(.+?)-") %>% .[,2] 
    results[idx, "genres"] <- html_content %>% 
      html_node("div.views-field-field-genre div.field-content") %>%
      html_text(trim=TRUE)
    results[idx, "sensuality"] <- html_content %>% 
      html_node("div.views-field-field-sensuality div.field-content") %>%
      html_text(trim=TRUE)
    pubs <- html_content %>% 
      html_nodes("div.amazon-details div.views-field") %>%
      html_text(trim=TRUE)
    if(length(pubs) > 0) {
      if (str_detect(pubs[1], "Published:")) {
        results[idx, "published"] <- str_replace(pubs[1], "Published:\\s+", "")
        if (length(pubs) == 2) {
          results[idx, "publisher"] <- str_replace(pubs[2], "Publisher:\\s+", "")
        }
      } else if (str_detect(pubs[1], "Publisher:")) {
        results[idx, "publisher"] <- str_replace(pubs[1], "Publisher:\\s+", "")
      }
    }
  }
  write_csv(results, "resultdata.csv")
  results
}


collect_pages()
collect_reviews()
results <- extract_pages()
View(results)


