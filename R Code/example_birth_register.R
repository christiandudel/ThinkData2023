### ThinkData 2023: Introduction to administrative register data
### First example: Vital registration/birth register data

## Data source
## https://www.nber.org/data/vital-statistics-natality-data.html
## Documentation: 
## https://data.nber.org/natality/1990/
## In particular:
## https://data.nber.org/natality/1990/Nat1990doc.pdf 

## Goal: Age-specific fertility rates for women and men


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

# Load data using data.table, combined with unzip
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

# Descriptive look at age range of mothers and fathers
dat$dmage %>% summary # Mothers
dat$dfage %>% summary # Fathers

dat$dmage %>% table # Mothers
dat$dfage %>% table # Fathers

# Caveat: Age of mother sometimes imputed, not well documented what that means
dat$mageimp %>% table
dat %>% filter(mageimp==1) %>% select(dmage) %>%table

# What to do with very low and high ages?
dat <- dat %>% mutate(dmage = case_match(dmage, 
                                         10:14~15,
                                         .default=dmage),
                      dfage = case_match(dfage, 
                                         10:14~15,
                                         60:89~59,
                                         99~NA,
                                         .default=dfage))

# Quick look at result
dat$dfage %>% table(useNA="always") %>% prop.table
# So there is actually a non-negligible proportion of missing values

# Coverage
dat$restatus %>% table

# Restrict to mothers who are residents of the U.S.
dat <- dat %>% filter(restatus!=4)
# This will miss births to resident mothers if the birth happens abroad.
# This variable is not available for fathers. 
# So for men, the analysis will include some fathers who are not residents,
# while it potentially will miss some resident men who have a child with a
# mother abroad. Might cancel.

# Get aggregated data
mothers <- dat %>% group_by(dmage) %>% count
fathers <- dat %>% group_by(dfage) %>% count

# Rename variables
mothers <- mothers %>% rename(Age=dmage)
fathers <- fathers %>% rename(Age=dfage)

# Remove missing value for fathers (!)
fathers <- fathers %>% na.omit


### Merging with exposures #####################################################

#install.packages("remotes")
#library(remotes)
#install_github("timriffe/TR1/TR1/HMDHFDplus")
library(HMDHFDplus)

# For HMD
pw <- "password"
user <- "username"

# Get exposures
exposures <- readHMDweb(CNTRY="USA",
                        item="Exposures_1x1",
                        password=pw,
                        username=user)

# Remove unnecessary data
exposures <- exposures %>% select(Year,Age,Female,Male) %>% filter(Year%in%1990)

# Merge
mothers <- left_join(mothers,exposures)
fathers <- left_join(fathers,exposures)


### Results ####################################################################

# Calculate rates
mothers <- mothers %>% mutate(rate=n/Female)
fathers <- fathers %>% mutate(rate=n/Male)

# Example plot
mothers %>% ggplot(aes(x=Age,y=rate)) + geom_line()
fathers %>% ggplot(aes(x=Age,y=rate)) + geom_line()
