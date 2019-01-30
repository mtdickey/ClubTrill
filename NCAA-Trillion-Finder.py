# -*- coding: utf-8 -*-
"""
Trillionaire Finder
Created on Tue Nov 15 11:09:11 2016

@author: Michael
"""

# Libraries
from bs4 import BeautifulSoup
import urllib  # urllib2 in Python 2.7
import pandas as pd
from datetime import date, timedelta


# Open website and collect links
base = 'http://www.sports-reference.com/cbb/boxscores/'
append1 = 'index.cgi?month='
append2 = '&day='
append3 = '&year='
## Replace below with the appendices and each possible month/day/year
response = urllib.request.urlopen(base) # in urllib2 for 2.7: urllib2.urlopen()
html = response.read()
soup = BeautifulSoup(html, 'lxml')

# Gather urls for each day
start_date = date(2010, 11, 8)
end_date = date.today()

## Function to get all days between two dates
def daterange(start_date, end_date):
    for n in range(int ((end_date - start_date).days)):
        yield start_date + timedelta(n)

# Try opening each site and if "No games found." is not in the html then add it to the list of days we need to use
dayUrls = []

for single_date in daterange(start_date, end_date):
    year = str(single_date.year)
    month = str(single_date.month)
    day = str(single_date.day)
    response = urllib.request.urlopen(base+append1+month+append2+day+append3+year)
    html = response.read()
    if 'No games found.' not in str(html):
        dayUrls.append(base+append1+month+append2+day+append3+year)

# Initialize Trillionaire lists
playerNames = []
minutes = []
trillGameUrls = []
gameInfos = []

gameBase = 'http://www.sports-reference.com'

#for each day:
for dayUrl in dayUrls:
    print(dayUrl)
    ## Get the games from that day
    response = urllib.request.urlopen(dayUrl) # in urllib2 for 2.7: urllib2.urlopen()
    html = response.read()
    soup = BeautifulSoup(html, 'lxml')
    urlholders = soup.find_all('td', {'class':'right gamelink'})
    gameUrls = []
    for url in urlholders:
        if url.find('a') is not None:
            gameUrls.append(url.find('a')['href'])
    
    # for each game within the day
    for url in gameUrls:        
        response2 = urllib.request.urlopen(gameBase + url)
        html2 = response2.read()
        soup2 = BeautifulSoup(html2, 'lxml')
        tableRows = soup2.find_all('tr')
        info = soup2.find('h1').getText()
        # Iterate through players and box scores
        for row in tableRows:
            if row.find('td', {'data-stat':'mp'}) is not None and row.find('td', {'data-stat':'mp'}).getText() != '':
                if int(row.find('td', {'data-stat':'mp'}).getText()) is not 0 and int(row.find('td', {'data-stat':'fga'}).getText()) == 0 and int(row.find('td', {'data-stat':'fta'}).getText()) == 0 and int(row.find('td', {'data-stat':'trb'}).getText()) == 0 and int(row.find('td', {'data-stat':'ast'}).getText()) == 0 and int(row.find('td', {'data-stat':'tov'}).getText()) == 0 and int(row.find('td', {'data-stat':'blk'}).getText()) == 0 and int(row.find('td', {'data-stat':'stl'}).getText()) == 0 and int(row.find('td', {'data-stat':'pf'}).getText()) == 0:
                    playerNames.append(row.find('th', {'scope':'row'})['csk'])
                    minutes.append(int(row.find('td', {'data-stat':'mp'}).getText()))
                    trillGameUrls.append(url)
                    gameInfos.append(info)

print(playerNames)
print(minutes)

trill = pd.DataFrame(data={'Players':playerNames, 'Minutes': minutes, 'GameUrl': trillGameUrls, 'GameInfo': gameInfos})
trill['Players'].value_counts() # number of times each player has recorded a Trill
trill.groupby(['Players'])['Minutes'].sum().sort_values() # Greatest Trillionaire by minutes
