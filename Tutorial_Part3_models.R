Installations required:
R, R packages [h2o, jpeg, pdist, shiny], nConvert


### ASSIGN PATHS TO YOUR DIRECTORIES ###
initial_data_dir <- "~/Documents/ShoeFetish/shoefetish01/shoefetish010/"
working_data_dir <- "~/Documents/ShoeFetish/shoefetish01/shoefetish010/"


### INITIAL DATA TRANSFORMATION ###
# ADD: read "pre-directory"
# ADD: convert data in pre-directory to correct format and write into directory
# ADD: read "directory"


### READ IN DATA ###
library(jpeg)
x <- readJPEG(directory[1])
vec <- c(x[,])
if (length(directory) > 1) {
    for (i in 2:length(directory)) {
      x <- readJPEG(directory[i])
      y <- c(x[,])
      vec <- cbind(vec, y)
    }
}
vec2 <- as.data.frame(t(vec))
remove(i,x,vec,y)

predictors <- colnames(vec2)


### LOAD INITIAL DATA TO H2O ###
###       AND KMEANS CLUSTER ###
initial_h2o <- as.h2o(localH2O, vec2, key="initial")
model_cluster <- h2o.kmeans(data=initial_h2o, centers=9, init="furthest")

### USE CLUSTERS AS LABELS ###
###      AND REUPLOAD TO H2O ###
vec2$label <- paste("a_", as.character( as.data.frame( h2o.predict( object=model_cluster, newdata=initial_h2o))$predict),sep="")
train_h2o <- as.h2o(localH2O, vec2, key="train")
  

### TRAIN AUTOENCODER ###
model_main <- h2o.deeplearning(x=predictors, y="label",data=train_h2o, activation="Tanh",hidden=c(250,50,10,50,250), epochs=8, autoencoder=TRUE)

### SAVE MODEL ###
print(h2o.saveModel(model_main, dir=getwd(), name="model_main", save_cv=TRUE, force=TRUE))
  
### SAVE TRANSFORMED INITIAL SET ###
ptrain_main <- as.matrix(h2o.deepfeatures(train_h2o,model_main,layer=3))
save(ptrain_main, file=paste(getwd(),"/model_main/ptrain_main.RData",sep=""))




### TEST A NEW IMAGE AGAINST PRE-LOADED MODEL ###
a <- input$newpic[1,]
listtestfiles <- a$name

system('rm ~/Documents/ShoeFetish/shoefetish01/shoefetish010/testdata/current.jpg')
system('rm ~/Documents/ShoeFetish/shoefetish01/shoefetish010/testdata/current_small.jpg')
system(paste('~/Documents/ShoeFetish/shoefetish01/shoefetish010/nconvert -out jpeg -o ~/Documents/ShoeFetish/shoefetish01/shoefetish010/testdata/current.jpg -resize 100 100 -edgedetect light -grey 128 ', a$datapath, sep=""))
system(paste('~/Documents/ShoeFetish/shoefetish01/shoefetish010/nconvert -out jpeg -o ~/Documents/ShoeFetish/shoefetish01/shoefetish010/testdata/current_small.jpg -resize 100 100 ', a$datapath, sep=""))

library(jpeg)
x <- readJPEG('~/Documents/ShoeFetish/shoefetish01/shoefetish010/testdata/current.jpg')
vec <- c(x[,])
vec3 <- as.data.frame(t(vec))
remove(x,vec)

test_h2o <- as.h2o(localH2O, vec3, key="test")

ptest <- as.matrix(h2o.deepfeatures(test_h2o,model_main,layer=-1))
a1 <- pdist(ptest,ptrain_main)

a1_dist <- a1@dist
a1_n <- a1@n
a1_p <- a1@p
b1 <- matrix(a1_dist, nrow=a1_n, ncol=a1_p)
scores1 <- b1[1,]
q1 <- as.data.frame(scores1)
q1$files <- directory
q1$goodfiles <- directory_show
q1 <- q1[order(q1$scores),]

c(q1$goodfiles[1],q1$goodfiles[2],q1$goodfiles[3],q1$goodfiles[4],q1$goodfiles[5])


