### ThinkData 2023: Introduction to administrative register data
### First example: Vital registration/birth register data


## Data source
## https://www.nber.org/data/vital-statistics-natality-data.html
## Documentation: 
## https://data.nber.org/natality/1990/desc/natl1990/


### Packages ###################################################################

library(httr)
library(data.table)
library(dtplyr)
library(tidyverse)
library(microbenchmark)


### Download data ##############################################################

# Avoiding 'here' and other neat things as to keep this straightforward
# for Stata/SPSS/... users

# Where is the data?
url <- "https://data.nber.org/natality/1990/natl1990.csv.zip"

# Where to save it?
zipfile <- "U:/Tmp/natl1990.csv.zip"

# Download
GET(url, write_disk(zipfile, overwrite = TRUE), progress() )

# Check size 
file.size(zipfile)


### Loading data ###############################################################

# Load data using data.table
command <- "unzip -cq"
cmdzip <- paste(command,zipfile)
dat <- fread(cmd = cmdzip)

# Quick look at data
names(dat)
table(dat$dfage)

# Speed: data.table
microbenchmark(table(dat$dmage),times=3,unit="seconds") # base R
microbenchmark(dat %>% select(dmage) %>% table,times=3,unit="seconds") # tidy

# Speed: normal data.frame/tibble
dat2 <- read_csv(zipfile)
microbenchmark(table(dat2$dmage),times=3,unit="seconds") # base R
microbenchmark(dat2 %>% select(dmage) %>% table,times=3,unit="seconds") # tidy
rm(dat2)

# Tidy workflow with dtplyr: automatic, but if needed explicit:
dat %>% group_by(dmage) %>% count
dat %>% lazy_dt %>% group_by(dmage) %>% count %>% as_tibble


### Data cleaning ##############################################################

# Descriptive look at age range
dat$dmage %>% table # Mothers
dat$dfage %>% table # Fathers


### Merging with exposures #####################################################


### Results ####################################################################
