if (!require("pacman")) install.packages("pacman")
library(pacman)
p_load(tidyverse, rvest)


# Get article links ------------------------------------------------------------

## Define page n link ----
link <- 'https://corrieredellumbria.it/archivio/1140/perugia?_gl=1*s5spva*_up*MQ..*_ga*MTMxMzM2NDU3OC4xNzQwNDk2NDg1*_ga_KY50W4FLZ7*MTc0MDUwMzQyMS4zLjEuMTc0MDUwMzQ0MS4wLjAuMTkxODI2OTM1Mw..&page='

## setup up loop to iterate 82 times (one for each page) ----

### setup vectors
article_urls <- tibble()
i <- 1

### start loop
while (i <= 82) {
  
  ilink <- paste0(link, i) # generate page i link
  
  html <- read_html(ilink) # Parse html
  
  article_url <- html |> 
    html_elements('.cont .titolo a') |> # Get article link 
    html_attr('href') 
  article_urls <- article_urls |> 
    bind_rows(as_tibble(article_url)) # append to url list
  
  i <- i + 1 # add 1 to i
}
rm(i)

## restore corrupt urls
article_urls <- ifelse(startsWith(article_urls$value, 'news'),
                       paste0('https://corrieredellumbria.it/', article_urls$value),
                       article_urls$value)

# Scrape article data ----------------------------------------------------------

## define empty df ----
CorrUmbriaPG <- tibble(title = character(),
                       date = character(),
                       text = character())

## set language to italian
Sys.setlocale(locale="it_IT.UTF-8")
## initialise loop ----
for (i in 1:NROW(article_urls)) {
  print(paste('scraping article number', i, 'of', NROW(article_urls)))
  
  article <- read_html(article_urls[i]) # parse html
  
  title <- article |> 
    html_element('.titolo_articolo') |> # extract title
    html_text()
  
  text <- article |> 
    html_element('.testoResize') |> # extract text
    html_text()
  
  date <- article |> 
    html_element('.data') |> 
    html_text2() |> 
    str_extract('\\d{2}\\s[A-Za-z]+\\s\\d{4}') # extract date
  
  n_row <- tibble(
    title = title,
    date = date,
    text = text # defining new df row
  )
  
  CorrUmbriaPG <- n_row |> 
    bind_rows(CorrUmbriaPG) # append to original df
  
}

## convert date column to date format
CorrUmbriaPG <- CorrUmbriaPG |> 
  mutate(date = date |> as_date(format = "%d %B %Y"))

# Export corpus as RDS

write_rds(CorrUmbriaPG, 'Rawdata/CorrUmbriaPG.RDS')
