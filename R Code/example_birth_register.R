## https://www.nber.org/data/vital-statistics-natality-data.html
## Documentation: https://data.nber.org/natality/1990/desc/natl1990/

# Packages
library(httr)
library(data.table)
library(dtplyr)
library(tidyverse)

# Paths
url <- "https://data.nber.org/natality/1990/natl1990.csv.zip"
zipfile <- "U:/Tmp/natl1990.csv.zip"

# Download
GET(url, write_disk(zipfile, overwrite = TRUE), progress() )

# Size 
file.size(zipfile)

# Load data
command <- "unzip -cq"
cmdzip <- paste(command,zipfile)
dat <- fread(cmd = cmdzip)

# Quick look at data
names(dat)
table(dat$dfage)

# Speed
library(microbenchmark)
dat2 <- read_csv(zipfile)
microbenchmark(table(dat$dmage),times=3,unit="seconds")
microbenchmark(table(dat2$dmage),times=3,unit="seconds")
microbenchmark(dat %>% select(dmage) %>% table,times=3,unit="seconds")
microbenchmark(dat2 %>% select(dmage) %>% table,times=3,unit="seconds")
rm(dat2)

# Tidy workflow with dtplyr: automatic, but if needed explicit
dat %>% group_by(dmage) %>% count
dat %>% lazy_dt %>% group_by(dmage) %>% count %>% as_tibble



