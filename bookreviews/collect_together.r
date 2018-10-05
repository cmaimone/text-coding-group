library(httr)
library(rvest)
library(glue)
library(stringr)

setwd("bookreviews")

BASEDOMAIN <- "https://www.rtbookreviews.com"

extract_links <- function(pagenum) {
  listpage <- read_html(glue("pagedownloads/{pagenum}.html"))
  listpage %>%
    html_nodes(".views-field-title span a") %>%
    html_attr("href") 
  
}

download_page <- function(pagenum) {
  r <- GET(glue("https://www.rtbookreviews.com/book-review?page={pagenum}"))
  write(content(r, as = "text"), file=glue("pagedownloads/{pagenum}.html"))
}

collect_reviews <- function() {
  for (page in c(342)) {#(page in 0:1281) {
    links <- extract_links(page)
    for (link in links) {
      print(link)
      r <- GET(glue("https://www.rtbookreviews.com{link}"))
      pagename <- str_replace(link, "/book-review/", "")
      write(content(r, as = "text"), file=glue("reviewdownloads/{pagename}.html"))
    }
  }
}

process_reviews <- function() {
  reviewfiles <- list.files(path="reviewdownloads", pattern="html$", full.names = TRUE)
  result <- data.frame(url=rep(NA, length(reviewfiles)), 
                       title=NA, author=NA)
  for (i in 1:length(reviewfiles)) {
    #print(reviewfiles[i])
    rhtml <- read_html(reviewfiles[i])
    result$url[i] <- reviewfiles[i]
    result$title[i] <- rhtml %>%
      html_node("h1.title") %>%
      html_text()
    result$author[i] <- rhtml %>%
      html_node("div.field-name-field-authors") %>%
      html_text()
    result$author[i] <- str_replace(result$author[i], "Author\\(s\\):\\s", "")
  }
  return(result)
}


#download_page(342)
#extract_links(342)
#collect_reviews()
process_reviews() %>% head()
