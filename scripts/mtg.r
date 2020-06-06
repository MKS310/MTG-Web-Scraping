library(rjson)
#devtools::install_github("sailthru/tidyjson")
#pkg<-c("tidyjson", "plyr", "dplyr", "ggplot2", "stringr")
#install.packages(pkg)
#install.packages("rjson")
#install.packages("wordcloud")

library(rjson)
library(plyr)
library(dplyr)
library(ggplot2)
library(stringr)
#library(mallet)
library(wordcloud)

setwd("~/Documents/maggie/school/DS745/text_proj")
setwd("~/text_proj")
decks<- fromJSON(file = "decks.json")

####FUNCTIONS
removeBlanks <- function(x) { x[which(x!="")] }

makeFlexTextChunks <- function(doc.object,chunk.size=1000,percentage=TRUE) {

  words.lower <- tolower(doc.object)
  words.lower <- gsub("[^[:alnum:][:space:]']"," ",words.lower)
  words.l <- strsplit(words.lower,"\\s+")
  word.v <- unlist(words.l)
  x <- seq_along(word.v)
  if(percentage) {
    max.length <- length(word.v)/chunk.size
    chunks.l <- split(word.v,ceiling(x/max.length))
  } else {
    chunks.l <- split(word.v, ceiling(x/chunk.size))
    if(length(chunks.l[[length(chunks.l)]]) <=
       length(chunks.l[[length(chunks.l)]])/2) {
      chunks.l[[length(chunks.l)-1]] <- c(chunks.l[[length(chunks.l)-1]],
                                          chunks.l[[length(chunks.l)]])
      chunks.l[[length(chunks.l)]] <- NULL
    }
  }
  chunks.l <- lapply(chunks.l,paste,collapse=" ")
  chunks.df <- do.call(rbind,chunks.l)
  return(chunks.df)
}

getWordSegmentTableList <- function(doc.object,chunk.size=10) {

  words.lower <- tolower(doc.object)
  words.alpha <- str_replace_all(words.lower,"[[:cntrl:]]", "")
  words.alpha2 <- str_replace_all(words.alpha, "[^[:alpha:]]", " ")
  words.l <- strsplit(words.alpha2, "\\W")
  word.v <- unlist(words.l)
  max.length <- length(word.v)/chunk.size
  x <- seq_along(word.v)
  chunks.l <- split(word.v,ceiling(x/max.length))
  chunks.l <- lapply(chunks.l,removeBlanks)
  freq.chunks.l <- lapply(chunks.l,table)
  rel.freq.chunk.l <- lapply(freq.chunks.l,prop.table)
  return(rel.freq.chunk.l)
}

my.mapply <- function(x) {
  my.list <- mapply(data.frame,ID=seq_along(x),x,SIMPLIFY=FALSE,
                    MoreArgs=list(stringsAsFactors=FALSE))
  my.df <- do.call(rbind,my.list)
  return(my.df)
}


numDecks = length(decks)
deck_df = data.frame(color=rep(NA, numDecks), 
                     name=rep(NA, numDecks), 
                     card_text=rep(NA, numDecks),
                     weight = rep(NA, numDecks))

COMMANDER = 1
freq_t = c()
for( i in 1:numDecks ){
  deck_df$color[i] <- paste(decks[[i]]$Cards[[COMMANDER]]$colors, collapse=', ' )
  if(deck_df$color[i] == ""){
    deck_df$color[i] = "Colorless"
  }
  deck_df$name[i] <- decks[[i]]$DeckName
  #print(decks[[i]]$DeckName)
  deck_df$weight[i] <- as.numeric(decks[[i]]$NumberOfDecks)
  
  numCards = length(decks[[i]]$Cards)
  
  deck_text = c()
  for(j in 1:numCards){
    if(!is.null(decks[[i]]$Cards[[j]]$text)){
    card_text = decks[[i]]$Cards[[j]]$text
    deck_text = append(deck_text,card_text)
    }else{
      deck_text[j] = " "
    }
  }
  deck_df$card_text[i] =  paste(deck_text, collapse = "")
}
remove(decks)
deck_df$color = factor(deck_df$color)
freq_t = c()
for(k in 1:numDecks){
  temp_t = rep(factor(deck_df$color[k]),deck_df$weight[k])
  freq_t = append(freq_t,temp_t)
}

dfl <- ddply(deck_df, .(color), summarize, y=sum(weight))
dfl <- dfl[order(dfl$y, decreasing = TRUE),]
dfl$color <- factor(dfl$color,levels = dfl$color)

area.color <- rep(NA, length(dfl$color))
area.color[1:5] <- "red"
a <- ggplot(dfl, aes(x = color,y=y
                         )
            )   

a + geom_col(aes( fill = area.color), width = 0.5) + 
  ggtitle("Popularity of Deck Colors in Current MTG Commander Metagame") +
  ylab("Number of Decks Reported on MTGgoldfish.com") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90,hjust=0.95,vjust=0.2),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none")

remove(dfl,freq_t)
#So we are looking at Black,Red,Blue; Red,Blue; Black; Green,Blue; and Red decks


BRB <- 'Black,Red,Blue'
RB <- 'Red,Blue'
B <- 'Black'
GB <- 'Green,Blue'
R <- 'Red'

top5colors = c(BRB,RB,B,GB,R)

deck.obj <- deck_df[which(deck_df$color %in% top5colors),]

deck.obj<-deck_df

freqs.l <- lapply(deck.freqs.l,my.mapply)
freqs.df <- do.call(rbind,freqs.l)

head(freqs.df)



## 13 topic modelling
chunk.size = 1000
#deck.obj<-deck_df
####13 Topic Modelling

deck.freqs.l <- list()
for(i in 1:length(deck.obj$name)){
  chunk.data.l <- getWordSegmentTableList(deck.obj$card_text[i],10)
  deck.freqs.l[[deck.obj$name[i]]] <- chunk.data.l
}

topic.m <- NULL
for(i in 1:length(deck.obj$name)) {
  chunk.m <- makeFlexTextChunks(deck.obj$card_text[i],chunk.size,percentage=FALSE)
  textname <- deck.obj$name[i]
  segments.m <- cbind(paste(textname,segment=1:nrow(chunk.m),sep="_"),chunk.m)
  topic.m <- rbind(topic.m,segments.m)
}

documents <- as.data.frame(topic.m,stringsAsFactors=F)
colnames(documents) <- c("id","text")

# 13.5 Simple Topic Modelling
stoplist <- paste(tdir,"./scripts/stoplist2.csv",sep="")
mallet.instances <- mallet.import(documents$id,documents$text,stoplist,FALSE,
                                  token.regexp="[\\p{L}']+")

topic.model <- MalletLDA(num.topics=5)


topic.model$loadDocuments(mallet.instances)
vocabulary <- topic.model$getVocabulary()

length(vocabulary)
head(vocabulary)
vocabulary[1:50]

word.freqs <- mallet.word.freqs(topic.model)
head(word.freqs)

topic.model$setAlphaOptimization(40,80)
topic.model$train(400)

# 13.6 Explore the model

topic.words.m <- mallet.topic.words(topic.model,smoothed=TRUE,normalized=TRUE)

vocabulary <- topic.model$getVocabulary()
colnames(topic.words.m) <- vocabulary
topic.words.m[1:3,1:3]

mallet.top.words(topic.model,topic.words.m[1,],10)
mallet.top.words(topic.model,topic.words.m[2,],10)
mallet.top.words(topic.model,topic.words.m[3,],10)
mallet.top.words(topic.model,topic.words.m[4,],10)
mallet.top.words(topic.model,topic.words.m[5,],10)


# 13.7 Visualize the Model with Wordcloud

topic.top.words.1 <- mallet.top.words(topic.model,topic.words.m[1,],300)
topic.top.words.2 <- mallet.top.words(topic.model,topic.words.m[2,],300)
topic.top.words.3 <- mallet.top.words(topic.model,topic.words.m[3,],300)
topic.top.words.4 <- mallet.top.words(topic.model,topic.words.m[4,],300)
topic.top.words.5 <- mallet.top.words(topic.model,topic.words.m[5,],300)
op <- par(mfrow = c(1, 1), # 2 x 2 pictures on one plot
          pty = "s")
par(op)
#par(mfrow=c(2,3))
wordcloud(topic.top.words.1$words,topic.top.words$weights,c(4,.8),rot.per=0,
          random.order=FALSE)
wordcloud(topic.top.words.2$words,topic.top.words$weights,c(4,.8),rot.per=0,
          random.order=FALSE)
wordcloud(topic.top.words.3$words,topic.top.words$weights,c(4,.8),rot.per=0,
          random.order=FALSE)
wordcloud(topic.top.words.4$words,topic.top.words$weights,c(4,.8),rot.per=0,
          random.order=FALSE)
wordcloud(topic.top.words.5$words,topic.top.words$weights,c(4,.8),rot.per=0,
          random.order=FALSE)


# 13.8 Topic Probability

doc.topics.m <- mallet.doc.topics(topic.model,smoothed=T,normalized=T)

file.ids.v <- documents[,1]
head(file.ids.v)

file.id.1 <- strsplit(file.ids.v,"_")
file.chunk.id.1 <- lapply(file.id.1,rbind)
file.chunk.id.m <- do.call(rbind,file.chunk.id.1)
head(file.chunk.id.m)

doc.topics.df <- as.data.frame(doc.topics.m)
doc.topics.df <- cbind(file.chunk.id.m[,1],doc.topics.df)

doc.topic.means.df <- aggregate(doc.topics.df[,2:ncol(doc.topics.df)],
                                list(doc.topics.df[,1]),mean)
#TOPIC 1
barplot(doc.topic.means.df[,"V1"],names=c(1:249))
group1.l <- which(doc.topic.means.df$V1>.5)

filenames1 <- as.character(doc.topic.means.df[group1.l,"Group.1"])
deck_df$color[which(deck_df$name%in%filenames1)]

#TOPIC 2
barplot(doc.topic.means.df[,"V2"],names=c(1:249))
group2.l <- which(doc.topic.means.df$V2>.5)

filenames2 <- as.character(doc.topic.means.df[group2.l,"Group.1"])
deck_df$color[which(deck_df$name%in%filenames2)]

#TOPIC 3
barplot(doc.topic.means.df[,"V3"],names=c(1:249))
group3.l <- which(doc.topic.means.df$V3>.5)

filenames3 <- as.character(doc.topic.means.df[group3.l,"Group.1"])
deck_df$color[which(deck_df$name%in%filenames3)]

#TOPIC 4
barplot(doc.topic.means.df[,"V4"],names=c(1:249))
group4.l <- which(doc.topic.means.df$V4>.5)

filenames4 <- as.character(doc.topic.means.df[group4.l,"Group.1"])
deck_df$color[which(deck_df$name%in%filenames4)]

#TOPIC 5
barplot(doc.topic.means.df[,"V5"],names=c(1:249))
group5.l <- which(doc.topic.means.df$V5>.5)

filenames5 <- as.character(doc.topic.means.df[group5.l,"Group.1"])
deck_df$color[which(deck_df$name%in%filenames5)]