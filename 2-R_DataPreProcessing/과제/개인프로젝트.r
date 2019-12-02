rm(list=ls())
# install.packages("rvest")
library(rvest) # for scraping functions.
library(stringr) #

pageSize <- 50
baseUrl <- "https://stackoverflow.com"

maxNumPages <- 20 # 20 pages * 50 pageSize => 1000��
maxCommentsPerPage <- 20

so <- list() # stackover flow object

indexPage <- list()
indexPage$url <- "https://stackoverflow.com/questions/tagged/r?sort=frequent&pageSize=50&page=1"
indexPage$xmldoc <- read_html(indexPage$url)

so$indexPage <- indexPage # so�� indexPage �߰�

# calculate the number of pages
totalNumPages <- html_node(indexPage$xmldoc, "#mainbar > div.grid.ai-center.mb16 > div.grid--cell.fl1.fs-body3.mr12")
totalNumPages <- html_text(totalNumPages)
totalNumPages <- str_extract_all(totalNumPages, "[[:digit:],]{1,}")
totalNumPages <- str_replace_all(totalNumPages, ",", "")
totalNumPages <- floor((as.integer(totalNumPages)-1)/pageSize)+1
totalNumPages <- ifelse(totalNumPages < 1, 1, totalNumPages)

so$totalNumPages <- totalNumPages # so�� totalNumPages �߰�

question <- list()
question$uris <- str_extract_all(as.character(indexPage$xmldoc), "question-summary-[[:digit:]]{1,}")[[1]] # 1 > fixed
question$qid <-  str_extract(question$uris, "[[:digit:]]{1,}")
question$cssSelector <- paste("#", question$uris, " > div.summary > h3 > a", sep = "")
question$href <- rep(NA, length(question$cssSelector))
question$text <- rep(NA, length(question$cssSelector))
article$a <- rep(NA, length(question$cssSelector))

so$question <- question # so�� question �߰�
articles <- list()
for(idxQuestion in 1:length(question$cssSelector)){
  idxQuestion <- 1
  article <- list()
  article$a[idxQuestion]
  article$a[idxQuestion] <- html_nodes(indexPage$xmldoc, question$cssSelector[idxQuestion]) # 1 to i
  article$href[idxQuestion] <- html_attr(article$a[idxQuestion], "href") # link
  article$text[idxQuestion] <- html_text(article$a[idxQuestion]) # title
  
  article$href.full <- paste(baseUrl, article$href[idxQuestion], sep = "")
  cur.href <- article$href.full
  
  # ������ votes ���ϱ�
  question$xmldoc <- read_html(cur.href)
  question$votes <- html_nodes(question$xmldoc, "#question > div.post-layout > div.votecell.post-layout--left > div > div")
  question$votes <- html_text(question$votes)
  question$votes <- as.integer(question$votes)
  
  # ������ content ���ϱ�
  question$content <- html_node(question$xmldoc, "#question > div.post-layout > div.postcell.post-layout--right > div.post-text")
  question$content <- html_text(question$content)
  
  # ������ comments ���ϱ�
  question$commentsTable <- html_nodes(question$xmldoc, paste("#comments-", question$qid[idxQuestion], " > ul", sep = "")[1]) # 1 to i
  question$comments <- html_nodes(question$commentsTable, ".comment-copy")
  question$comments <- html_text(question$comments)
  question$comments
  
  # ����� id ���ϱ�
  answer <- list()
  answer$xmldoc <- html_nodes(question$xmldoc, ".answer")
  answer$aid <- html_attr(answer$xmldoc, "data-answerid")
  answer$aid.cssSelector <- paste("#answer-", answer$aid, " > div > div.votecell.post-layout--left > div > div.js-vote-count.grid--cell.fc-black-500.fs-title.grid.fd-column.ai-center", sep = "")
  answer$aid.cssSelector
  
  # ���� votes ���ϱ�
  #TODO: for���� vector �������� ��ü�ϱ�
  # answer$votes <- vector("list", length(answer$aid.cssSelector))
  answer$votes <- rep(NA, length(answer$aid.cssSelector))
  for(i in 1:length(answer$aid.cssSelector)){
    tmp.votes <- html_node(question$xmldoc, answer$aid.cssSelector[i])
    tmp.votes <- html_text(tmp.votes)
    answer$votes[i] <- as.integer(tmp.votes)
  }
  answer$votes
  
  
  # ���� content ���ϱ�
  #TODO: pre�±� ���� �ؾ� �մϴ�.
  answer$content.xmldoc <- html_nodes(answer$xmldoc, ".post-text")
  answer$content <- html_text(answer$content.xmldoc)
  
  # ���� comments ���ϱ�
  # 
  # answer$commentTable <- html_nodes(answer$xmldoc, ".comments-list")
  answer$comment <- vector("list", length(answer$aid))
  for(i in 1:length(answer$aid)){
    answer$commentTable.cssSelector <- paste("#comments-", answer$aid[i], " > ul", sep = "") # 1 to i
    answer$commentTable <- html_nodes(answer$xmldoc, answer$commentTable.cssSelector)
    answer$commentTable <- html_nodes(answer$commentTable, "li")
    answer$comment[[i]] <- html_text(answer$commentTable) # comment�� character vector�� �̾���
  }
  articles[[idxQuestion]] <- article
}


# db�� ���� - SQLite ���
# SQLite ���

# install.packages("RSQLite")
library(RSQLite)

dbName <- "./stack_overflow.sqlite"
# con <- dbConnect(RSQLite::SQLite(), dbName = dbName)
con <- dbConnect(RSQLite::SQLite(),
                 dbname = dbName)
dbListTables(con)
dbWriteTable(con, "answer$comment", as.data.frame(answer$comment))
dbListTables(con)
dbListFields(con, "answer$comment")
dbReadTable(con, "answer$comment")
res <- dbSendQuery(con, "SELECT * FROM 'answer$comment'")
dbFetch(res)
dbClearResult(res)
dbDisconnect(con)
