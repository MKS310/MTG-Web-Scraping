# MTG-Web-Scraping

## Background
My family and I love playing Magic the Gathering, so I created this project for a final exam for an Unstructured Data Analysis Class during my Master's degree program. The goal was to analyze the deck structure of the tournament decks in the current "meta" (a term used to describe the current cards in popular use). I also wanted to analyze the text on the cards since MTG card narratives contain a lot of interesting Fantasy-genre descriptions.


## Introduction
**Magic: the Gathering** is a strategy card game owned by Wizards of the Coast with an estimated 20 million players worldwide as of 2015 [@duffy_2015]. Over 15,000 unique cards [@relikter_2016] have been created for the game. Players can build their own decks using cards that are legal for the format they are playing. For one particular format, called Commander or EDH, almost all 15,000 cards are eligible for inclusion in a player’s deck. 

A commander deck consists of 100 cards, pursuant to the following rules [@mtg_2019]:

+ Each deck must contain exactly 100 cards, including its commander.
+ Other than basic lands, each card in a Commander deck must have a different English name.
+ A card can be included in a Commander deck only if every color in its color identity is also found in the color identity of the deck's commander.

The ecosystem of Commander decks is vast and wild. Players rely on creativity, available resources and tournament deck lists to craft a seemingly infinite variety of decks. Naturally, certain types of decks become popular based on “what everyone else is playing” [@magic_2007] and what everyone is playing to beat everyone else. This is called the metagame. Many websites report deck statistics and metagame analysis. One such website is MTG Goldfish. They derive their metagame analysis from current MTG tournament games. MTGgoldfish.com publishes a list of commander metagame decks, along with the cards in the decks and the prices of the cards. 

A MTG card looks like the following image. Each card has a name, cost, type, and power/toughness. Most cards, with the exception of basic lands, have text. The card text that makes up each Commander deck in the metagame is the interest of this analysis.

![](mtg_card.png) [@magic]

## Motivation

Each card has a rich story. I suspect that by modelling the topics of the text, we can see the story of the current Commander-format metagame. I also suspect that the topics will naturally be grouped by color combination. 

## Related Work

Some work has been done analyzing MTG card text. One study [@Zilio_2018] outlines the methodology used to train neural nets to predict a card type based on imagery. They also trained neural networks to generate card text to match an image.

In addition, several researchers looked into the ability to use artificial intelligence to play MTG. They showed that the games' outcomes were non-computable: "Magic: The Gathering does not fit assumptions commonly made by computer scientists while modeling games. We conjecture that optimal play in Magic is far harder than this result alone implies, and leave the true complexity of Magic and the reconciliation of Magic with existing theories of games for future research," [@churchill2019magic]. The framework of rules that leads to this conclusion is largely buried in the text on each individual card.

## Dataset Description

The dataset is a compilation of Commander deck data scraped from MTGgoldfish.com using a python script (./scripts/mtg_scraper2.py) and an MTG software development kit (sdk).

## Variables

The data is saved as a JSON file and contains the following information: 

+ Deck ID
+ Deck name
+ Number of decks of type reported to MTG Goldfish
+ Percent of Metagame represented by a deck
+ Deck price (paper deck)
+ Deck price (online deck)
+ Cards:
  + Name
  + Mana cost
  + Colors
  + Text

The card colors are related to the flavor of the text. Angels and knights are white; Dragons, volcanos and goblins are red.  In this analysis, the variables of interest are the deck name, the colors, and the text.

## Methodology

The following steps were taken to perform the topic modelling analysis:

### Find the Data
The website and data requirements were analyzed.

  + MTGGoldfish.com is a leading source for MTG tournament deck lists. This is among the best sources for analyzing the current metagame of any MTG format.
  
### Web Scraping with Python

I build a webscraper in Python 3.5 using beautiful soup. The deck data was saved as a JSON file.

### Process Data

The JSON file was loaded into R and processed into a data frame

```
```{r Visualize Color Distribution, echo=FALSE, message=FALSE, warning=FALSE}
#create a dataframe for ggplot to plot
#y value is the sum of the number of decks for each color combo
dfl <- ddply(deck_df, .(color), summarize, y=sum(weight))
#reorder so plot goes from tallest to shortest
dfl <- dfl[order(dfl$y, decreasing = TRUE),]
dfl$color <- factor(dfl$color,levels = dfl$color)
area.color <- rep(NA, length(dfl$color)) #used to color top 5 red
area.color[1:5] <- "red"
a <- ggplot(dfl, aes(x = color,y=y ))   
a + geom_col(aes( fill = area.color), width = 0.5) + 
  ggtitle("Popularity of Deck Colors in Current MTG Commander Metagame") +
  xlab("Color Combinations of Commander Decks (Top 5 indicated in red)") +
  ylab("Number of Decks Reported") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90,hjust=0.95,vjust=0.2),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none")
remove(dfl)
```














## Web Scraping and Building the Dataset

The largest part of the project was building the dataset. There are some great sites online that track cards and deck configurations. I wanted to build a dataset that consisted of deck configurations pulled from the latest tournaments and after contact several web admins for API or database access, I resigned to scraping the data myself. Of course, I checked out the sites' robots.txt files first.

After scraping and formatting the data into a JSON format, I enriched the data using an API that provided more information about each individual card. 

[The Jupyter Notebook](https://github.com/MKS310/MTG-Web-Scraping/beautiful_soup_demo.ipynb) for this project was created as a demo of the web scraping portion.
I gave this demo to the Python Users Group at my corporate job to demonstrate some web scraping ideas.

## Analyzing the Data

I used R to do some basic text mining operations to remove stopwords, punctuation, and capitalization, I made word clouds for the text on each group of 

![](https://github.com/MKS310/MTG-Web-Scraping/blob/master/cloud1_1.png)

[The Report file](https://github.com/MKS310/MTG-Web-Scraping/blob/master/schweihs_text.pdf) demonstrates the NLP side of this analysis. 
