setwd("pdfs") # because my project is a level higher in the textcoding repo

library(pdftools)
library(purrr)

txt <- pdf_text("example_dissertations_polisci/Weiss_Powerful Patriots.pdf")

# first page text
txt[1]
cat(txt[1])

# second page text
txt[2]
cat(txt[2])

# txt is a vector, one element per page, \n denoting new lines
# note that you don't really get blank lines (you can get these with other pdf parsers)

# get all of the text together

# all the texti n a single string
full_text3 <- paste(txt, collapse="\n") # could keep page breaks by specifying collapse argument with something like ----------

# one line per vector element (page breaks are gone)
full_text <- map(txt, strsplit, "\n") %>% unlist()
# or 
full_text <- strsplit(full_text3, "\\n")[[1]]

# Another option to keep page breaks: list, one page per list item, each page is a character vector
full_text2 <- sapply(txt, strsplit, "\n")

