setwd("C:/Users/Michael/Documents/Side Projects/ClubTrill")

library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

trill2010 <- read.csv("ClubTrill2010.csv")
trill2010$Season <- "2010-11"
trill2011 <- read.csv("ClubTrill2011.csv")
trill2011$Season <- "2011-12"
trill2012 <- read.csv("ClubTrill2012.csv")
trill2012$Season <- "2012-13"
trill2013 <- read.csv("ClubTrill2013.csv")
trill2013$Season <- "2013-14"
trill2014 <- read.csv("ClubTrill2014.csv")
trill2014$Season <- "2014-15"
trill2015 <- read.csv("ClubTrill2015.csv")
trill2015$Season <- "2015-16"

# Manipulating the GameInfo strings
clubTrill <- rbind(trill2010, trill2011, trill2012, trill2013, trill2014, trill2015)
clubTrill$GameInfo <- gsub(" vs. ", ",", clubTrill$GameInfo)
clubTrill$GameInfo <- gsub(" Box Score", "", clubTrill$GameInfo)

## Split game info into 4 separate variables
clubTrill$Team1 <- str_split_fixed(clubTrill$GameInfo, ",", 4)[,1]
clubTrill$Team2 <- str_split_fixed(clubTrill$GameInfo, ",", 4)[,2]
clubTrill$DatePart <- str_split_fixed(clubTrill$GameInfo, ",", 4)[,3]
clubTrill$Year <- str_split_fixed(clubTrill$GameInfo, ",", 4)[,4]
clubTrill$Date <- as.Date(paste0(clubTrill$DatePart, ", ", clubTrill$Year), format = " %B %d, %Y")
clubTrill$DateFake <- as.Date(paste0(clubTrill$DatePart, ", 1999"), format = " %B %d, %Y")


## Take care of players that have the same name by determining team name (not captured in script) ##
clubTrill$playersTeam <- NA
for(i in 1:nrow(clubTrill)){  ## This loop takes AWHILE...
  if(length(which(clubTrill$Players == clubTrill$Players[i])) > 1){
    ## Determine of the two teams, which one has more appearances with this player name
    team1 <- length(which(clubTrill$Players == clubTrill$Players[i] &
                          (clubTrill$Team1 == clubTrill$Team1[i] | 
                            clubTrill$Team2 == clubTrill$Team1[i])))
    team2 <- length(which(clubTrill$Players == clubTrill$Players[i] &
                            (clubTrill$Team1 == clubTrill$Team2[i] | 
                               clubTrill$Team2 == clubTrill$Team2[i])))
    if(team1 > team2){clubTrill$playersTeam[i] <- clubTrill$Team1[i]}
    else if(team2 > team1){clubTrill$playersTeam[i] <- clubTrill$Team2[i]}
    ## Otherwise for ties, leave NA
  }
}
save(clubTrill, file = "clubTrill.RData")
load("clubTrill.RData")

# Who had the longest trillions?
clubTrill[which(clubTrill$Minutes == max(clubTrill$Minutes)),]

### Vizzes ####
# How many trillions go beyond 1 minute?
ggplot(clubTrill[which(clubTrill$Minutes <= 10),], aes(x=Minutes)) + geom_bar() +
  labs(y = "Count", title = "Trillions By Minutes Played") + scale_x_discrete(limits = 1:10) + 
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 13),
        title = element_text(size = 18))

## Boxplots of Minutes per Trill by season 
plot <- ggplot(clubTrill, aes(y = Minutes, x = Season)) + geom_boxplot(aes(label = GameInfo)) +
      theme(axis.title = element_text(size = 16),
      axis.text = element_text(size = 13),
      title = element_text(size = 18))
ggplotly(plot)  # tooltips not labeled with player as we'd like

## When do the trillions occur throughout the season?
# setting up the Jan.-April to come after Nov/Dec. on this graph
clubTrill$DateFake[which(month(clubTrill$DateFake) %in% c(1,2,3,4))] <- as.Date(paste0(
  month(clubTrill$DateFake[which(month(clubTrill$DateFake) %in% c(1,2,3,4))]), "/",
  day(clubTrill$DateFake[which(month(clubTrill$DateFake) %in% c(1,2,3,4))]), "/2000"
), format = "%m/%d/%Y")
countThroughYear <- clubTrill %>% group_by(DateFake) %>% summarise(count = n())

ggplot(countThroughYear, aes(x = DateFake, y = count)) + geom_line(size = 1.2) +
  labs(x = "Date", y = "Count", title = "Occurrences of Trillions Throughout the Season")
## Nothing too insightful here, just a huge spike before Christmas, followed by a dip (because of # of games)
# and a tapering off throughout March/April tourney time
## Potential modification for future: 

## Top players by minutes
PlayerTotals <- head(clubTrill %>% group_by(Players, playersTeam) %>% 
                    summarise(TotalMin = sum(Minutes)) %>% arrange(desc(TotalMin)), 10) 
PlayerTotals$PlayerName <- paste0(substr(word(PlayerTotals$Players, 2, sep = ","), 1, 1), ". ", word(PlayerTotals$Players, 1, sep = ","))
ggplot(PlayerTotals, aes(x = reorder(PlayerName, -TotalMin), y = TotalMin)) + geom_bar(stat = "identity") +
  labs(x = "\n\nPlayer", y= "Minutes in Games Without a Stat\n") +  # adding another space between player name and title for space for logos
  ggtitle(expression(atop("NCAA Trillionaires", atop(italic("2010-11 to 2015-16 Seasons"), "")))) + 
  theme(axis.title = element_text(size = 16),
        axis.text.x = element_text(size = 13),
        axis.text.y = element_text(size = 14),
        title = element_text(size = 18))

## Top players by number of trills -- each trill colored by minutes
PlayerObs <- clubTrill[which(clubTrill$Players %in% PlayerTotals$Players &
                             clubTrill$playersTeam %in% PlayerTotals$playersTeam),]
PlayerObs$minGroups <- ifelse(PlayerObs$Minutes <= 1, "1", ifelse(PlayerObs$Minutes <= 2, "2", ifelse(PlayerObs$Minutes <= 3, "3", ifelse(
                              PlayerObs$Minutes <= 4, "4", "5+"))))
PlayerObs$minGroups <- factor(PlayerObs$minGroups, levels = c("1", "2", "3", "4", "5+"))
PlayerObs$PlayerName <- paste0(substr(word(PlayerObs$Players, 2, sep = ","), 1, 1), ". ", word(PlayerObs$Players, 1, sep = ","))

ggplot(PlayerObs, aes(x = factor(PlayerName, levels = c("J. Flash",
                                                        "B. Price",
                                                        "J. Polson",
                                                        "C. Sager",
                                                        "P. Johnson",
                                                        "M. Roelke",
                                                        "D. Peera",
                                                        "N. Musters",
                                                        "D. Hubert",
                                                        "J. Floyd")), fill = minGroups)) + 
  geom_dotplot(stackgroups = T, binwidth = .325, method = "histodot") +
  labs(x = "\n\nPlayer", y = "Number of Trills\n\n", fill = "Minutes Played") +
  ggtitle(expression(atop("NCAA Trillionaires", atop(italic("2010-11 to 2015-16 Seasons"), "")))) + 
  theme(axis.text.y = element_blank(),
        axis.title.y = element_text(size = 15, margin = margin(0,0,0,20)),
        axis.title.x = element_text(size = 15, margin = margin(0,0,20,0)),
        axis.text.x = element_text(size = 11),
        title = element_text(size = 16),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  guides(fill = guide_legend(override.aes = list(size=9))) +
  scale_fill_manual(values = c("1" = "#ffffcc",
                               "2" = "#c2e699",
                               "3" = "#78c679",
                               "4" = "#31a354",
                               "5+" = "#006837")) 

PlayerObs %>% filter(minGroups != "5+") %>% group_by(PlayerName) %>% summarise(TotalMin = sum(Minutes)) %>% arrange(desc(TotalMin))
