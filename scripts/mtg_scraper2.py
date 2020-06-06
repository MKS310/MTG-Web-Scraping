from urllib.request import urlopen
from bs4 import BeautifulSoup
from urllib.error import HTTPError
from urllib.error import URLError
import re
from mtgsdk import Card
import json


# Get the html page from a url
def getDeckPage(url):
    try:
        html = urlopen(url)
    except HTTPError as e:
        print(e)
    except URLError as e:
        print('The server could not be found!')
    try:
        page = BeautifulSoup(html.read(), 'html.parser')
        html.close()
    except AttributeError as e:
        return None
    return page


# Get the list of deck urls from an html page
def getDeckList(page):
    deck_urls = []
    try:
        deck_url = page.findAll('span', {'class': "deck-price-paper"})
        for i in deck_url:
            for link in i.findAll('a'):
                deck_urls.append(link.attrs['href'])
    except AttributeError as e:
        return None
    return deck_urls


# Get the name of a deck from the deck page
def getDeckName(page):
    try:
        for i in page.findAll('h2', {'class': 'deck-view-title'}):
            name =i.get_text()
    except AttributeError as e:
        return None
    return name


# Get the list of cards from the deck page
def getDeckCards(page):
    card_list = []

    try:
        page = page.find('table', {'class': "deck-view-deck-table"})

        link_finder = re.compile('^(.*(\/price).*)', re.IGNORECASE)

        for i in page.findAll('a', {'href': link_finder}):
            card = i.get_text()
            if '//' in card.split():
                card = card.split(' // ')
                for c in card:
                    card_list.append(c)
            else:
                card_list.append(card)
    except AttributeError as e:
        return None
    return card_list


# Get card info from mtgsdk using the list of cards
def getDeck(cardlist):
    deck_list = {}
    try:
        for j in range(0, len(cardlist)):
            one_card = [(card.name, card.text, card.colors, card.mana_cost) for card in cards if card.name == cardlist[j]]
            if not one_card:
                deck_list[j] = {'name': cardlist[j], 'text': 'NA',
                                'colors': 'NA', 'mana_cost': 'NA'}
            else:
                deck_list[j] = {'name': one_card[0][0], 'text': one_card[0][1],
                                'colors': one_card[0][2], 'mana_cost': one_card[0][3]}
    except AttributeError as e:
        return None
    return deck_list


# Load all MTG cards locally to search through. Roughly 44,000 cards, or 8 Mb text
cards = Card.all()

# Target Domain
DOMAIN = 'https://www.mtggoldfish.com'

# Use the following URL to make a list of links to all the commander decks in current metagame
myurl = 'https://www.mtggoldfish.com/metagame/commander/full#paper'
html = urlopen(myurl)
bs = BeautifulSoup(html, 'html.parser')
html.close()
decks = {}

# Make a list of links to all the commander decks in current metagame
deck_page_urls = getDeckList(bs)

# Loop through the deck URLs to get data on each deck and each card
for i in range(10,len(deck_page_urls)):
    myurl = DOMAIN + deck_page_urls[i]
    deckID = re.findall('[0-9]{5,6}', myurl)
    deckPage = getDeckPage(myurl)
    deckName = getDeckName(deckPage).strip()
    deckCards = getDeckCards(deckPage)
    deck = getDeck(deckCards)

    deckStats = deckPage.find('p').get_text().strip().split()

    # Number of Decks of same kind on MTG Goldfish  #
    numDecks = deckStats[0]
    # % of Meta #
    pctMeta = re.sub('[^0-9.]+', '', deckStats[2])
    # $ Deck #
    deckPrice_paper = list(deckPage.find('div', {'class': 'price-box paper'}).div.next_siblings)[1].get_text()
    deckPrice_online = list(deckPage.find('div', {'class': 'price-box online'}).div.next_siblings)[1].get_text()

    decks[i] = {'ID': deckID, 'DeckName': deckName, 'NumberOfDecks': numDecks,
                'PercentOfDecks': pctMeta, 'PaperPrice': deckPrice_paper,
                'OnlinePrice': deckPrice_online, 'Cards': deck}
    print("Deck %s done." % i)

# Save the 'decks' dictionary to a json file for reading and cleaning in a jupyter notebook
json = json.dumps(decks)
f = open("decks.json", "w")
f.write(json)
f.close()


