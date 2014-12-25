library(RSQLite)
library(stringr)
sqlite    <- dbDriver("SQLite")

# Import old anki database
v6 <- dbConnect(sqlite,"v6.anki2")

# Import koohii database from `rtk` repo
# in `hochanh/rtk`, branch `rtk`
# commit 3cb4026cc890f76fd2489374a3d4e72f0fcd5ce3
v6.koo <- readRDS("v6-koohii.rds")
v6.koo <- as.data.frame(v6.koo)

# We create a table of new database
# with 2 columns: flds, sflds (i.e. v4 number):
v6.flds <- dbGetQuery(v6, "select flds from notes")
v6.split <- str_split(v6.flds[,1], "\037")

v6.note <- matrix(rep(0L,2*2200), ncol=2, 
										dimnames=list(1:2200,c("sfld","flds")))
for (i in 1:2200) {
	v6.vec <- v6.split[[i]]
	v6.v6 <- v6.vec[3] # V6 number
	v6.v4 <- v6.vec[2] # V4 number
	v6.ka <- v6.vec[5] # Kanji
	v6.key <- v6.vec[4] # Keyword
	v6.on <- v6.vec[17] # On-Yomi
	v6.kun <- v6.vec[18] # Kun-Yomi
	v6.sks <- v6.vec[9] # Stroke count
	v6.ski <- v6.vec[6] # Stroke image
	v6.ko <- v6.koo[v6.koo$no==v6.v4, 3] # Koohii top 5 stories
	v6.ko <- str_replace_all(v6.ko, "\n\n", "<br><br>")
	v6.col <- str_c(v6.ka,v6.key,v6.on,v6.kun,v6.sks,v6.ski,v6.ko,
									sep="\037")
	v6.26 <- str_c(rep("",26), collapse="\037")
	v6.col <- paste0(v6.col, v6.26)
	v6.note[i,1] <- v6.v6
	v6.note[i,2] <- v6.col
}

v6.note <- as.data.frame(v6.note, stringsAsFactors = FALSE)

# Call old note from v6.anki2
notes.old <- dbGetQuery(v6, "select * from notes")
notes.new <- notes.old

for (i in 1:2200) {
	no.sfld <- notes.new[i, 8]
	notes.new[i, 7] <- v6.note[v6.note$sfld==no.sfld, 2]
}

# Write table
dbWriteTable(v6, "notes_2", notes.new)

dbSendQuery(v6, 
						"UPDATE notes 
						SET flds = (SELECT notes_2.flds 
						FROM notes_2 
						WHERE notes_2.sfld = notes.sfld);")

dbSendQuery(v6, "DROP TABLE notes_2")

# Disconnect
dbDisconnect(v6)
