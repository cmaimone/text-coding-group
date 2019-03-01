library(tidyverse)
library(tidytext)
library(lubridate)
library(stringr)
library(widyr)

# devtools::install_github("juliasilge/tidytext")
# update: install.packages("Rcpp")

# Get the data
unzip("feinstein.zip")

# utility function for later - to highlight words in text
highlight_terms <- function(filename, terms) {
  text <- read_file(paste0("Feinstein/", filename))
  tempDir <- tempfile()
  dir.create(tempDir)
  htmlFile <- file.path(tempDir, "highlight.html")
  text <- gsub(paste0("(",paste(terms, collapse="|"),")"), paste0("<mark>","\\1", "</mark>"), text, ignore.case = TRUE)
  text <- gsub("\\n", "<br><br>",text)
  write(text, htmlFile)
  viewer <- getOption("viewer")
  viewer(htmlFile)
}


# tidytext approach ----
# ----------------------------------

# read in files, split words
pr <- map_df(list.files(path="Feinstein/", pattern = ".txt$"), ~ tibble(txt = read_file(paste0("Feinstein/",.x))) %>%
         mutate(filename = .x) %>%
         unnest_tokens(word, txt))

# get date and ID from filename
pr <- pr %>%
  separate(filename, into=c("date", "id"), sep="Feinstein", remove=FALSE) %>%
  mutate(date=dmy(date)) %>%
  mutate(id=str_extract(filename, "\\d+"))

# dictionary with complete words all equal weights
education <- c("education", "schools", "teach")

# binary topical indicator
pr <- pr %>% 
  group_by(filename) %>%
  mutate(ontopic = any(word %in% education)) %>%
  ungroup()

# counting number of terms in the document
education_scores <- pr %>%
  mutate(score=word %in% education) %>%
  group_by(filename) %>%
  summarize(docscore=sum(score)) %>%
  arrange(desc(docscore))
education_scores

# some options for looking at articles
viewer <- getOption("viewer")
viewer("Feinstein/15Dec2005Feinstein292.txt")
cat(read_file("Feinstein/15Dec2005Feinstein292.txt"))

# with term highlighting!
highlight_terms("15Dec2005Feinstein292.txt", education)


# topical term co-occurrence: count
co <- pr %>% 
  filter(word %in% education) %>% 
  pairwise_count(word, filename, diag=TRUE) %>% 
  spread(item2, n) 
co

# proportions
co %>%
  mutate_at(vars(-item1), funs(./diag(as.matrix(co[,-1]))))

# correlation
correlations <- pr %>% 
  filter(word %in% education) %>% 
  pairwise_cor(word, filename, diag=TRUE) %>% 
  spread(item2, correlation) 
correlations

# Other co-occurring terms: find terms that appear more often in eduction docs than others

tfidf <- pr %>%
  group_by(filename) %>%
  mutate(ontopic = any(word %in% education)) %>%
  ungroup() %>%
  anti_join(stop_words) %>% # let's take out stop words for this one
  group_by(ontopic, word) %>%
  count() %>%  
  filter(n >= 3) %>%  # drop words that only appear 1 or 2 times just to make data smaller
  bind_tf_idf(word, # column with words
              ontopic, # column with groupings
              n) %>% # column with word counts
  ungroup() 

tfidf %>%
  arrange(desc(tf_idf)) %>%
  mutate(word = factor(word, levels = rev(unique(word)))) %>% 
  filter(ontopic) %>% 
  top_n(15)



# for more complicated terms, you can use regex patterns or partial terms

education2 <- c("educ", "school", "teach")

pr_text <- map_df(list.files(path="Feinstein/", pattern = ".txt$"), ~ tibble(txt = read_file(paste0("Feinstein/",.x))) %>%
               mutate(filename = .x)) %>%
                 separate(filename, into=c("date", "id"), sep="Feinstein", remove=FALSE) %>%
                 mutate(date=dmy(date)) %>%
                 mutate(id=str_extract(filename, "\\d+"))

pr_text <- pr_text %>%
  mutate(ontopic = str_detect(txt, regex(paste(education2, collapse="|"), ignore_case=TRUE)))

# how do results compare to the above?
table(pr_text$ontopic)
length(unique(pr$filename[pr$ontopic]))


# what new documents where picked up?
pr_text$filename[pr_text$ontopic & !pr_text$filename %in% unique(pr$filename[pr$ontopic])]

highlight_terms("9Mar2007Feinstein368.txt", education2)



