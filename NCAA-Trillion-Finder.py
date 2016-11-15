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
import datetime

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
date = datetime.datetime.today()-datetime.timedelta(days=15)
date_list = [date - datetime.timedelta(days=x) for x in range(0, 365)]

# Try opening each site and if "No games found." is not in the html then add it to the list of days we need to use
dayUrls = []
for date in date_list:
    year = str(date.year)
    month = str(date.month)
    day = str(date.day)
    response = urllib.request.urlopen(base+append1+month+append2+day+append3+year)
    html = response.read()
    if 'No games found.' not in str(html):
        dayUrls.append(base+append1+month+append2+day+append3+year)

# Initialize Trillionaire vectors
playerNames = []
minutes = []

gameBase = 'http://www.sports-reference.com'

#for each day:
for dayUrl in dayUrls[121:(len(dayUrls)-1)]:
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
        # Iterate through players and
        for row in tableRows:
            if row.find('td', {'data-stat':'mp'}) is not None:
                if int(row.find('td', {'data-stat':'mp'}).getText()) is not 0 and int(row.find('td', {'data-stat':'fga'}).getText()) == 0 and int(row.find('td', {'data-stat':'trb'}).getText()) == 0 and int(row.find('td', {'data-stat':'ast'}).getText()) == 0 and int(row.find('td', {'data-stat':'tov'}).getText()) == 0 and int(row.find('td', {'data-stat':'blk'}).getText()) == 0 and int(row.find('td', {'data-stat':'stl'}).getText()) == 0 and int(row.find('td', {'data-stat':'pf'}).getText()) == 0:
                    playerNames.append(row.find('th', {'scope':'row'})['csk'])
                    minutes.append(int(row.find('td', {'data-stat':'mp'}).getText()))

print(playerNames)
print(minutes)

trill = pd.DataFrame(data={'Players':playerNames, 'Minutes': minutes})
trill['Players'].value_counts() # number of times each player has recorded a Trill
trill.groupby(['Players'])['Minutes'].sum().sort_values() # Greatest Trillionaire by minutes

# Note 11/15 - 2PM: This has only run back to 2/28/2016