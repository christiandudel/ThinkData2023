### ThinkData 2023: Introduction to administrative register data
### Second example: Fake complex data

## Data source: 
## My personal imagination
## Documentation:
## None

## Goal: Risk of first birth by employment


### Packages ###################################################################

library(tidyverse)


### Status file ################################################################

# Load
file <- "Data/reg_status.csv"
reg_status <- read_csv(file)

# Discover (overview)
reg_status
reg_status %>% dim
reg_status %>% view
reg_status %>% summary

# Discover (variables)
reg_status$Year %>% table(useNA="always")
reg_status$Status %>% table(useNA="always")
reg_status$Gender %>% table(useNA="always")
reg_status$Cohort %>% table(useNA="always")

# Discover (nr of obs, nr of individuals, nr of obs per individual)
reg_status %>% dim # Obs
reg_status$ID %>% unique %>% length # Individuals
reg_status %>% group_by(ID) %>% count # Obs per person
# Validate the last step
reg_status %>% view # ...and count by hand

# Structure
# Not really necessary here: data is already in person-year format, works well

# What we not know yet: there is a row missing, let's add it:
additional_row <- reg_status %>% filter(ID==4 & Year ==2004)
additional_row <- additional_row %>% mutate(Year=2003)
reg_status <- rbind(reg_status,additional_row) %>% arrange(ID,Year)

# Clean (create variables)
reg_status <- reg_status %>% mutate(Age=Year-Cohort)
reg_status$Age %>% table()

# Clean (drop observations outside age range)
reg_status <- reg_status %>% filter(Age<50)
reg_status$Age %>% table()

# Discover (check observations with Status!=1)
reg_status$Status %>% table(useNA="always")
reg_status <- reg_status %>% group_by(ID) %>% mutate(check=any(is.na(Status)))
reg_status %>% filter(check) %>% view
# Let's perhaps keep this person 
reg_status <- reg_status %>% select(!check)


## Birth file ##################################################################

# Load
file <- "Data/births.csv"
births <- read_csv(file)

# Discover (overview)
births
births %>% dim
births %>% view
births %>% summary

# Discover (variables)
births$Year %>% table(useNA="always")

# Discover (births per person)
births %>% group_by(Mother) %>% count
births %>% group_by(Father) %>% count %>% ungroup %>% select(n) %>% table

# Enrich (birth events)
mothers <- births %>% select(Mother,Year) %>% rename(ID=Mother) %>% mutate(BirthM=1)
fathers <- births %>% select(Father,Year) %>% rename(ID=Father) %>% mutate(BirthF=1)
reg_status <- left_join(reg_status,mothers,by=c("ID","Year"))
reg_status <- left_join(reg_status,fathers,by=c("ID","Year"))
reg_status <- reg_status %>% mutate(BirthF=ifelse(is.na(BirthF),0,1),
                                    BirthM=ifelse(is.na(BirthM),0,1),
                                    Birth=BirthF+BirthM)

# Validate 
view(births) # Let's see whether the 1st birth in the data was assigned correctly
reg_status %>% filter(Year==2000 & Birth ==1) %>% view

# Validate some more
reg_status$Birth %>% sum
births %>% filter(Year%in%1990:2020 & !is.na(Mother)) %>% select(Mother) %>% count
births %>% filter(Year%in%1990:2020 & !is.na(Father)) %>% select(Father) %>% count
# => looks like we missed some births, but why?
view(births) # Some people in the birth register do not appear in pop register
births %>% filter(Year%in%1990:2020 & !is.na(Mother) & Mother%in%reg_status$ID) %>% select(Mother) %>% count
births %>% filter(Year%in%1990:2020 & !is.na(Father) & Father%in%reg_status$ID) %>% select(Father) %>% count
# Still one birth missing

# Validation still ongoing
mothers$MNR <- 1:dim(mothers)[1]
fathers$FNR <- 1:dim(fathers)[1]
reg_status <- reg_status %>% select(!c(Birth,BirthM,BirthF))
reg_status <- left_join(reg_status,mothers,by=c("ID","Year"))
reg_status <- left_join(reg_status,fathers,by=c("ID","Year"))
reg_status <- reg_status %>% mutate(BirthF=ifelse(is.na(BirthF),0,1),
                                    BirthM=ifelse(is.na(BirthM),0,1),
                                    Birth=BirthF+BirthM)

mothers %>% filter(Year%in%1990:2020 & !is.na(ID) & ID%in%reg_status$ID) %>% select(MNR)
reg_status$MNR %>% unique

fathers %>% filter(Year%in%1990:2020 & !is.na(ID) & ID%in%reg_status$ID) %>% select(FNR) 
reg_status$FNR %>% unique # Birth with FNR=6 is missing
# Which birth is that?
view(fathers)
births %>% filter(Father==4 & Year ==2003) %>% view
reg_status %>% filter(ID==4 & Year ==2003) %>% view
reg_status %>% filter(ID==4) %>% view
reg_status %>% filter(ID==4) %>% pull(Year) %>% diff
# So a year is missing for this person
# Let's add a year; this is in lines 45-48
# Because at that early stage it is easy to add something and then re-run 
# everything, will keep code less messy

# Clean
reg_status <- reg_status %>% select(!c(BirthF,BirthM,MNR,FNR))

# Enrich (parity)
births1990 <- births %>% filter(Year<1990)
fathers1990 <- births1990 %>% select(Father,Year)
mothers1990 <- births1990 %>% select(Mother,Year)
fathers1990 <- fathers1990 %>% group_by(Father) %>% count %>% na.omit %>% rename(ID=Father,pre1990F=n)
mothers1990 <- mothers1990 %>% group_by(Mother) %>% count %>% na.omit %>% rename(ID=Mother,pre1990M=n)
reg_status <- left_join(reg_status,fathers1990)
reg_status <- left_join(reg_status,mothers1990)

# Validate
reg_status %>% filter(ID%in%fathers1990$ID) %>% view # OK
reg_status %>% filter(ID%in%mothers1990$ID) %>% view # No births before 1990...
mothers1990 # ... but there are births before 1990
reg_status %>% filter(ID==9) %>% view # Person 9 is actually not in data anymore, too old

# Enrich (parity), continued
reg_status <- reg_status %>% group_by(ID) %>% arrange(ID,Year) %>% mutate(Parity=cumsum(Birth))
reg_status %>% view
reg_status <- reg_status %>% mutate(pre1990F=ifelse(is.na(pre1990F),0,pre1990F),
                                    pre1990M=ifelse(is.na(pre1990M),0,pre1990M),
                                    Parity=Parity+pre1990F+pre1990M)

# Validate
reg_status %>% filter(ID==2) %>% view # Look into data
reg_status$Birth %>% sum # Count births
reg_status %>% group_by(ID) %>% mutate(diff=Parity-lag(Parity)) %>% pull(diff) %>% na.omit %>% sum # Count births differently


### Employment register ########################################################

# Load
file <- "Data/job_spells.csv"
jobs <- read_csv(file)

# Unfinished