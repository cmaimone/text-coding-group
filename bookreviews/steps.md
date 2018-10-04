# Web Scraping

First, consider this as a complete disclaimer and warning of basically everything I could warn or disclaim against.  You should only be collecting data from sites that allow it, like government sites where you have a right to data.  Even then, you should use appropriate procedures and be respectful.

That said, the general process of collecting data from a website usually follows a workflow like this:

## Assess the Site

### How can I get at the content?

Open the website in a web browswer and use the inspection tools to see the source.  Right click on the page and view the source of the page to see if the content is contained within.  Search the source html for some string of content from the page that you're looking for.

Look at the page to see if elements are loading interactively.  If you change pages and/or update content, does the URL change as well?

You're trying to determine whether you can use a URL to retrieve the content from the html page, or whether you need to run a web browser, all the site to generate the content, and then collect what's on the page.  


### What's my collection strategy?

Once you figure out the technical issue of how you'll get the data from the website, how will you go about getting everything that you want?  Is there a page listing or linking to everything?  Does the URL have parameters in it (like IDs, dates, search terms) that you can manipulate/loop through?  Will you need to enter a search in a text box?  How will you actually get what you want?




## Collect the Pages

Unless you have a very small project, you want to separate the collection and processing steps.  Collect (download) the data and store it.  Then later process it.  You'll make mistakes while processing, and you don't want to have to recollect data every time you need to fix your processing scripts.  

You can collect from Python or R, but sometimes you can just as easily (or more easily) collect from the command line with curl or wget.

### Save the pages

Save the raw files that you download, just as you get them.  You'll need to figure out a naming scheme so you can identify the files and link them with the original URL later.  Using the plain URL is not great since it can have special characters that don't play well with file names/paths.  If there are natural ID numbers, you could use those.  Otherwise, another option is to have a master file that records a filename and the original URL, and add entries to that as you save the files.  

If you think you'll need a database later in the project, you can store the downloaded text directly in a database.  But saving each page as an individual file is also a good strategy at this stage.  Even if you do use a database later, you can load in the files pretty easily.

### Tracking Errors

As you're collecting, you may get various kinds of errors.  You can get network errors, where your connection goes out.  You can get bad response from the website, for urls that don't exist or other denied errors.  And you can get unexpected errors, such as when a website returns a response, but the page doesn't have the content you expect on it.  This last one can happen because formats and urls change, or some website will start returning error pages if they detect you collecting from them.  You should think about how you will detect and process errors, especially if you're collecting over a long period.


## Process the Pages

After you have pages collected, then you can work on extracting data from them.  There are a few ways to get the data out.

For simple pages, you might be able to use regular expressions to find what you're looking for in a page.  You may need to use regular expressions at a later stage regardless of how you initially get chunks of text, so sometimes it's just easier to start with them.

For most pages, you'll use a package like BeautfulSoup (Python) or rvest(R).  You can access elements of a webpage using information about the html tags, their css classes, IDs, and other elements.  XPath is one way to write expressions that identify elements of a page.  You can get the xpath for an element from the browser inspector tools.  The specific packages also have syntax that let you select elements by other characteristics.

General process here is to loop through loading each page you downloaded, extract what you need from the page, and then write that result to a csv file, put it in a database, or otherwise output the information to use later.  

Once everything is processed, you can compress the raw files you downloaded them and stash them somewhere.  It's always a good idea to keep them around though, as a record of what you did and in case you need to get more information out of them later.




# General Considerations

Many legal and ethical considerations when you're web scraping.  I'm not a lawyer.  A lot of the area concerning fair use, copyright, web access, etc. is undefined.  Just because something exists, doesn't mean you necessarily have a right to collect it and/or use it in research.  And even if you had a right, it might not be an ethical thing to do.


## Always

Be respectful when collecting from a site directly.  Put time between requests and don't strain the server.  The amount of time/strain is dependent on how popular the site is (more popular ones are generally more robust).

If an API is available, use the API.  If the API doesn't contain the data you want, you probably shouldn't be trying to collect it.  

Don't try to get around log-ins or paywalls.  That's a very good way to get in trouble, and to get the university in trouble if you do it from a campus network.  

Don't violate terms of service on a product licensed by the university.  For example, don't try scraping databases/sites you get access to through the library.  Talk to a librarian about how you might access data.

## Consider

Most sites have a robots.txt file that gives information about crawling a site.  It would be at the main domain.  Example: http://www.northwestern.edu/robots.txt.  These are parts of the site you generally shouldn't crawl.  A lot of times this is actually useful information about content you probably aren't interested it.  

Consider copyright.  It might be ok to collect some information for yourself, but it's another thing to publish a dataset, which might be required when you publish your research.  

Consider privacy.  If you're collecting data people put on the web, is it reasonable to use it in research?  Should you involve the IRB for a review?  Consider the differences between data that has been publicly posted, and data that may be behind a sign-in or paywall.  How will you protect people's data once you collect it?  Are there legal issues you might run into (European privacy laws)?

At least read the terms of service or license to know what you might be violating.

Consider talking to a company to see if they will share data with you for research.  This can be easier than trying to scrape it yourself, and there might be good opportunities for collaboration.

One of my personal guidelines is if I could sit and download information manually given enough time, it might be reasonable to write a script to collect that information instead on a similar schedule to what a human could do.  

## Other Notes

Sites use cookies to track who you are, even if you aren't logged in.  Be aware that the content you see might be different from the content other people see.  This is particularly true on search engines like Google.  Even in private mode, Google will know you're at Northwestern.  Search results will be different for you than for people in other places.  Time of day can also affect results, as can the series of searches you do.  Web content isn't universal, especially on big commercial sites.

There are commercial services that will scrape websites for you.  This is an option to consider especially if you want to collect something on an ongoing basis.  It's not cheap, but the time and effort to collect something over time is considerable.

If you just need a few pages or sites, there are browser extensions and other programs that will help you extract data from web pages that you're viewing.  Some even create data files for export.  These are a good option to consider if you could manually progress through the sites, but you're just looking for a little help to make it easier (if your programming skills aren't so strong yet).  


# Tutorials and Resources

Just a few; still working on compiling a good set of resources.

## Python

[Requests](http://docs.python-requests.org/en/master/): package to collect

[BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/bs4/doc/): package to extract.  Use version 4.

[Web Scraping Tutorial with Python: Tips and Tricks](https://hackernoon.com/web-scraping-tutorial-with-python-tips-and-tricks-db070e70e071) by Jekarerina Kokatjuhha: good coverage of many of the technical and other considerations about for how to do this; limited code on actually doing the steps.

[Python Web Scraping Tutorial Using BeautifulSoup](https://www.dataquest.io/blog/web-scraping-tutorial-python/): frm DataQuest.  What the title says.  A good introductory tutorial.

[How to Scrape Web Pages with BeautifulSoup and Python 3](https://www.digitalocean.com/community/tutorials/how-to-scrape-web-pages-with-beautiful-soup-and-python-3) from Digital Ocean

[Web scraping the President's lies in 16 lines of Python](https://www.dataschool.io/python-web-scraping-of-president-trumps-lies/) by Kevin Markham, Data School; inculdes code files and videos too.

## R

[httr](http://httr.r-lib.org/): site for the package, which you can install as you normally would an R package.

[rvest](https://github.com/hadley/rvest): you can install the package as you normally do; a few examples at the GitHub site with the code.

[Working with Web Data in R](https://data.metinyazici.org/2017/10/working-with-web-data-in-r.html) by M. Yazici

[Introduction to Scraping and Wrangling Tables from Research Articles](http://research.libd.org/rstatsclub/2018/03/19/introduction-to-scraping-and-wranging-tables-from-research-articles/#.W7ObR1JRe3C) by Steve Semick

[Web Scraping in R: rvest Tutorial](https://www.datacamp.com/community/tutorials/r-web-scraping-rvest) from DataCamp.  There's a DataCamp course too.

[Scraping HTML Text](http://bradleyboehmke.github.io/2015/12/scraping-html-text.html) by Bradley Boehmke; uses rvest

[Web scraping tutorial in R](https://towardsdatascience.com/web-scraping-tutorial-in-r-5e71fd107f32) by José Roberto Ayala Solares; R counterpoint to "Web scraping the President's lies in 16 lines of Python"


