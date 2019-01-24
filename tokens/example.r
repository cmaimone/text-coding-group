library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(tidytext) # easy to work with in tidyverse land


# read in data
ev311 <- read_csv("https://northwestern.box.com/shared/static/uvisy24w7necwtg17xp8umelrmazpxww.csv")

# above gives a warning; check out the issues
problems(ev311)

ev311 %>%
  filter(row_number() %in% problems(ev311)$row) %>%
  View()

# looks like bad zip codes were just converted to missing -- this is OK

# Let's get some basics

nrow(ev311)
hist(nchar(ev311$Description), breaks=100) # how many characters in each description?
summary(nchar(ev311$Description))

# Hmm, lots of missing -- what's going on there?

ev311 %>%
  filter(is.na(Description)) %>%
  View()


# Maybe the types of requests that don't need a description?

ev311 %>%
  mutate(missingdesc = is.na(Description)) %>%
  group_by(missingdesc, Title) %>%
  count() %>%
  arrange(Title, missingdesc) %>%
  View()

# Nope - sometimes just missing
# For ease, let's just filter out those without a description since we're going to work with the description

ev311 <- ev311 %>%
  filter(!is.na(Description))

# Ok, let's split descriptions into words

words <- ev311 %>%
  select(ID, Description) %>%      # We don't need to copy every variable with every word
  unnest_tokens(output=word,       # name of the output column to be created
                input=Description, # name of the column to process
                token="words",     # what level to tokenize -- words is the default
                drop=TRUE)         # don't include the input column (this is the default)

View(words)

# Output is one row per document-word

# Look at some examples of how it was parsed:

words %>%
  group_by(ID) %>%
  summarize(tokenized = paste(word, collapse=" ")) %>%  # join tokenized words back together with spaces in between
  left_join(ev311) %>% # join back to original data to get the Description
  select(ID, tokenized, Description) %>%  # drop the fields we don't need to look at
  View()

# In the above, look at what happens to punctuation, numbers, etc.
# The conversion to all lower case is an option in unnest_tokens.
# There are other tokenizers you can use to preserve URLs, hashtags, etc.

# Example
# Default
ev311 %>%
  filter(str_detect(Description, "http"), # pick examples with a URL
         nchar(Description) < 250) %>%    # Just look at short descriptions to make it easier
  select(ID, Description) %>%
  unnest_tokens("word", Description, drop=FALSE) %>%
  View()

# With different tokenizer options
ev311 %>%
  filter(str_detect(Description, "http"), # pick examples with a URL
         nchar(Description) < 250) %>%    # Just look at short descriptions to make it easier
  select(ID, Description) %>%
  unnest_tokens("word", Description, drop=FALSE,
                token="tweets") %>%    # word tokenization that preserves URLs, hashes, etc.
  View()

# Note that the above also parses times differently -- for example, it keeps 6:45am together, 
# where the default does not

# If we don't really care about numbers, special cases, etc. let's just use the default word options
# and count words to find frequent words

words %>%
  group_by(word) %>%
  count(sort=TRUE) %>%
  View()

# most of these most frequent words are "stop words" -- just common words.
# there are lists you can use, or you can make your own.
# In this example, you might treat "caller" as a stop word since it appears frequently
# or you might be interested in it.  Similarly, there is analysis you can do on use of pronouns, articles, etc.
# so you don't automatically want to exclude stop words.  But if you wanted to...

words %>%
  anti_join(stop_words) %>% # stop_words in part of tidytext.  It has a "word" column that we're joining on
  group_by(word) %>%
  count(sort=TRUE) %>%
  View()

# look at stop_words; lexicon column is the source of the list - could use just one or all
View(stop_words)


# What does the distribution of word counts look like:
words %>%
  anti_join(stop_words) %>% 
  group_by(word) %>%
  count(sort=TRUE) %>%
  ggplot(aes(n)) + 
  geom_histogram(bins=100) + 
  labs(y="Number of Words with Frequency",
       x="Word Frequency")

# You can see the drastic drop-off - most words hardly appear at all, with a few appearing a lot
# zoom in:

words %>%
  anti_join(stop_words) %>% 
  group_by(word) %>%
  count(sort=TRUE) %>%
  filter(n < 100) %>%
  ggplot(aes(n)) + 
  geom_histogram(bins=100) + 
  labs(y="Number of Words with Frequency",
       x="Word Frequency")

# still drastic dropoff even when you zoom into the low frequency words

# What if we want to count the number of documents each term appears in 
# rather than the overall count?

words %>%
  anti_join(stop_words) %>% # stop_words in part of tidytext.  It has a "word" column that we're joining on
  group_by(word) %>%
  summarize(doc_count=length(unique(ID)),
            total_count=n()) %>%
  arrange(desc(doc_count)) %>% # most frequent words first
  View()


# There's a lot we can do with word counts, but first, how else can we tokenize text?

# by sentences - you might do this as an intermediary step to know what sentence a word is in

sentences <- ev311 %>%
  select(ID, Description) %>%
  unnest_tokens(sentence_text, Description, 
                token="sentences",
                to_lower = FALSE) %>%  # don't convert to all lowercase
  group_by(ID) %>%
  mutate(sentence_num=row_number()) 

View(sentences)

# It does a pretty good job, but when text is in all caps or otherwise strange, 
# it might break sentences in the middle.  Also breaks on non-standard abbreviations 
# and numbers sometimes.

# Once you have sentences, you can then later tokenize sentences to words, 
# keeping sentence_num variable

sentences %>%
  unnest_tokens(word, sentence_text) %>%
  View()

# We can also get bigrams (two words in a row), or n-grams (generalizing this to n words in a row)

ev311 %>%
  select(ID, Description) %>%
  unnest_tokens(bigram, Description, token="ngrams", n=2) %>%  #n=2 for bigrams
  group_by(bigram) %>%
  count(sort=TRUE) %>%
  View()

  
# Ok, back to working with word counts.  One thing is to compare word frequencies between groups.
# Here, we could look at most frequent words by Title (which is request category)

# We want to use tf-idf, which tries to balance word frequency with word importance

# Here, we compute it based on Title (Title is the "document")

tfidf <- words %>%
  left_join(ev311) %>% # add back in Title and other variables
  select(ID, Title, word) %>% # get rid of stuff we don't need
  anti_join(stop_words) %>% # let's take out stop words for this one
  group_by(Title, word) %>%
  count() %>%  # get word counts by Title
  filter(n >= 3) %>%  # drop words that only appear 1 or 2 times just to make data smaller
  bind_tf_idf(word, # column with words
              Title, # column with groupings
              n) %>% # column with word counts
  ungroup() 

View(tfidf)  

# We care about words with high tf-idf

# Visualize
# first, find common categories

freqtitles <- ev311 %>%
  group_by(Title) %>%
  count(sort=TRUE) %>%
  ungroup() %>%  # turn grouping off
  top_n(6) %>%  # take 6 most common
  pull(Title)  # extract as a vector

tfidf %>%
  filter(Title %in% freqtitles) %>%
  arrange(desc(tf_idf)) %>%
  mutate(word = factor(word, levels = rev(unique(word)))) %>% 
  group_by(Title) %>% 
  top_n(15) %>% 
  ungroup %>%
  ggplot(aes(factor(word, levels = rev(unique(word))), tf_idf, fill = Title)) +
  geom_col(show.legend = FALSE) +
  labs(x = NULL, y = "tf-idf") +
  facet_wrap(~Title, ncol = 2, scales = "free") +
  coord_flip() 

# note that the plots look a little funky - this happens because some words are important in multiple groups

# fix: thanks to: 
# https://drsimonj.svbtle.com/ordering-categories-within-ggplot2-facets

tfidf %>%
  filter(Title %in% freqtitles) %>%
  group_by(Title) %>%
  top_n(15, tf_idf) %>%
  ungroup() %>%
  arrange(Title, tf_idf) %>%
  mutate(order = row_number()) %>% { # { let's us reference the data frame created above throughout the code below
    ggplot(., aes(x=order, y=tf_idf, fill = Title)) +
    geom_col(show.legend = FALSE) +
    labs(x = NULL, y = "tf-idf") +
    facet_wrap(~Title, ncol = 2, scales = "free") +
    coord_flip() + 
    scale_x_continuous(
      breaks = .$order,
      labels = .$word,
      expand = c(0,0)
    )
  }



  
  
  
  