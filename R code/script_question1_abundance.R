
# The first subsets only have the treatments "natural tree" (a) and "control" (b). 
# This subset is meant to answer if the trees themselves have an effect 
# (Abundance ~ Treatment).

###########################################################################################################
# Modelling Fish abundance as a function of Treatment and others
###########################################################################################################
# dev.off()

require(glmmTMB)
require(rockchalk)

rm(list=ls()) # cleaning memory

# Set working directory
#setwd("c:/")
library(lattice)  # For fancy multipanel graphs
# source("HighstatLibV7.R") # Function created by Zuur et al; not included (copyrighted, Highland Statistics Ltd)

# Import the data 
HTrees1 <- read.table(file = "data/abundance.tree.and.controls.txt",
                     header = TRUE,
                     dec = ".")

# explore the variables
names(HTrees1)

# Check how R is reading these variables (factors or numbers)
str(HTrees1)
HTrees1$Treatment <- as.factor(HTrees1$Treatment)
# DATA EXPLORATION STEPS:
#A Outliers in Y / Outliers in X ?
#B Collinearity among predictors ?
#C Relationships response vs predictors ?
#D Spatial/temporal aspects of sampling design (not relevant here) ?
#E Interactions (is the quality of the data good enough to include them?) ?
#F Zero inflation ?
#G Are categorical covariates balanced?

#A Outliers
par(mfrow = c(1, 2))
boxplot(HTrees1$Abundance, 
        main = "Abundance")
dotchart(HTrees1$Abundance, 
         xlab = "Range of data", 
         ylab = "Values")
# Worrysome outliers would be points sticking out a lot more fro the rest, 
# there are no important ones to worry about here. 

#B Collinearity among predictors
pairs(HTrees1[,c("Treatment","Lat","Long","Trees50", "DistIsland", 
                "DistReef", "WMI")])
#      lower.panel = panel.cor) # panel.cor is from HighstatLibV7.R, not included (copyrighted)
# From here you gather that the following variables cannot go as predictors 
# in the same model because they are highly correlated to each other:
# Lat cant go with Long
# Lat cant go with DistIsland
# Lat shouldnt go with DistReef
# Long cant go with DistIsland
# Long cant go with Trees50
# DistIsland cant go with Trees50
# DistReef cant go in with Trees 50
# DistReef perhaps shouldn't go in with WMI (but correlation is low)

# But collinearity between a factor and other variables is better tested with:
boxplot(Lat ~ factor(Treatment), 
        data = HTrees1,
        ylab = "TreePerimeter",
        xlab = "Treatment")
# Not colinear
boxplot(Long ~ factor(Treatment),
        ylab = "Lat",
        xlab = "Treatment",
        data = HTrees1)
# Not colinear
boxplot(Trees50 ~ factor(Treatment),
        ylab = "Trees50",
        xlab = "Treatment",
        data = HTrees1)
# Not colinear
boxplot(DistIsland ~ factor(Treatment),
        ylab = "DistIsland",
        xlab = "Treatment",
        data = HTrees1)
# Not colinear
boxplot(DistReef ~ factor(Treatment),
        ylab = "DistReef",
        xlab = "Treatment",
        data = HTrees1)
# Not colinear
boxplot(WMI ~ factor(Treatment),
        ylab = "WMI",
        xlab = "Treatment",
        data = HTrees1)
# Not colinear

# Explore relationships
boxplot(Abundance ~ factor(Treatment), 
        data = HTrees1,
        varwidth = TRUE,
        ylab = "Fish abundance",
        xlab = "Treatment",
        main = "")
# Apparent effect of Treatment on fish abundance

plot(Abundance ~ Trees50, data = HTrees1)
# Apparent effect of Trees50 on fish abundance 

plot(Abundance ~ DistIsland, data = HTrees1)
# Not so strong pattern

plot(Abundance ~ DistReef, data = HTrees1)
# Apparent negative relationship

plot(Abundance ~ WMI, data = HTrees1)
# No apparent relationship

#F. Zero inflation
sum(HTrees1$Abundance == 0)
sum(HTrees1$Abundance == 0) / nrow(HTrees1)
plot(table(HTrees1$Abundance)) 
# Not zero inflated

#G. Are categorical covariates balanced?
table(HTrees1$Treatment)
plot(table(HTrees1$Treatment), 
     type = "h",
     xlab = "Treatment values",
     ylab = "Number of observations per category")
# Yes

# Model:
# (1) Abundance is currently a count so you need a glm (Poisson distribution)
# If this changes to a density (somehow computing the area surveyed) then you can use an lm 
# (2) As predictors we need to include all non-colinear variables and when two are strongly colinear 
# with each other, we include only one of them and explain that a significant effect could be
# attributed to one or the other. 
# (3) We know there is dependency between tree/control of the same LocationID

names(HTrees1)
library(glmmTMB)
mod1 <- glmmTMB(Abundance ~ Treatment + Trees50 + WMI + DistReef + DistIsland
                + (1 | LocationID),
                family = nbinom1(),
                data = HTrees1)
summary(mod1)

# model checks and validation:
E1 <- resid(mod1, type = "pearson")
F1 <- fitted(mod1)
eta <- predict(mod1, type = "link")
par(mfrow = c(3,3), mar = c(5,5,2,2))
plot(x = F1, 
     y = E1,
     xlab = "Fitted values",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h = 0, v = 0, lty = 2)
# ugly - this plot is strange the left half is not too bad but shows heterogeneity of variance
# the right hand side makes it look like there is non-linearity (When there are points just on the
# upper side and not on the lower half of the plot giving the impression of a curve)  

plot(x = eta, 
     y = E1,
     xlab = "Eta",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h=0, v = 0, lty = 2)
# heterogeneity - mark this as a valid observation: Variance is much larger in natural trees
# comapred to the controls. Perhaps this is due to the fact that (as you will see in your 
# second code) fish counts are not only very dependent on tree perimeter but also 
# on aspect and their interaction. 

boxplot(E1 ~ Treatment, 
        ylab = "Pearson residuals",
        data = HTrees1,
        cex.lab = 1.5, 
        xlab = "Aspect")
abline(h = 0, v = 0, lty = 2)
# same heterogeneity between treatments as explained above

plot(x = HTrees1$DistIsland, 
     y = E1,
     xlab = "Distrance from Island (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

plot(x = HTrees1$DistReef, 
     y = E1,
     xlab = "Distrance from Reef (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

plot(x = HTrees1$WMI, 
     y = E1,
     xlab = "Water Motion Index",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

# Checking for spatial autocorrelation of residuals:
ai <- ranef(mod1)$cond$LocationID$`(Intercept)`
MyData = data.frame(ai = ai,
                    Lat = tapply(HTrees1$Lat, FUN = mean, INDEX = HTrees1$LocationID),
                    Lon = tapply(HTrees1$Long, FUN = mean, INDEX = HTrees1$LocationID))
plot(x = MyData$Lon,
     y = MyData$Lat,
     type = "n")
MyCol <- c("red","blue") [as.numeric(MyData$ai>= 0)+1]
MyCex <- 5 * abs(ai) / max(ai)
points(x = MyData$Lon,
       y = MyData$Lat,
       col = MyCol,
       cex = MyCex,
       pch = 1)
# What you see in this graph are the random effects for Location. They are supposed
# to be spatially un-correlated. I have plotted the ai versus latitude and longitude.
# Red circles are random effects that are positive, and blue ones are negative.
# Big circles are big ai's and small circles are small ai's. You are not supposed
# to see any spatial patterns in this graph.
# If all th blue ones would be on one side, and all the red ones 
# on the other side, then there is spatial correlation. ANd you
# would need to continue with an INLA analysis.
# We dont have that, we can trust this model.

# Overdispersion
E1 <- resid(mod1, type = "pearson")
N  <- nrow(HTrees1)
p  <- length(fixef(mod1)) + 1
Overdispersion <- sum(E1^2) / (N - p)
Overdispersion
# Overdispersed, As we talked - the next way to solve this is Bayesian 

# But for now, given the improvement of the model validation plots we trust the model and:
drop1(mod1, test = "Chi")
# according to this model abundance is strongly related to: 
# Treatment and Distance to the Reef seem positively and strongly related to fish abundance



###Zuur et al:use negative binomial model to account for overdispersion


names(HTrees1)
library(glmmTMB)
mod1 <- glmmTMB(Abundance ~ Treatment + DistReef
                + (1 | LocationID),
                family = nbinom1(),
                data = HTrees1)
summary(mod1)
mod1

##extract values for plotting

pp <- predict(mod1, interval = "confidence", type = "response", SE = TRUE)
pframe <- data.frame(DistReef = HTrees1$DistReef, pp)


MyData.4 <- data.frame(Treatment =levels(HTrees1$Treatment),
                       DistReef = mean(HTrees1$DistReef))
summary(MyData.4)
X4 <- model.matrix(~Treatment + DistReef, data = MyData.4)

betas4 <- fixef(mod1)$con
betas4

Covbetas4 <- vcov(mod1)$con

MyData.4$eta <- X4 %*% betas4 
mu4<-exp(MyData.4$eta) 


MyData.4$SE <- sqrt(diag(X4 %*% Covbetas4 %*% t(X4)))

#### plot abundance vs treatment ##################################################################################

library(ggplot2)
library(gridExtra)
p <- ggplot()
pal <- c("forestgreen", "grey40")

p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees1, 
                       aes(y = Abundance, x = Treatment, color = Treatment),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01,
                       alpha = 0.8) + scale_color_manual(values = pal)
p2
#p2 <- p2 + ggtitle("Fish Abundance vs Treatment") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("Number of fishes"), axis.title.x = element_text("Treatment"))
p2 <- p2 + ylab(expression(paste('Number of fishes')))
p2 <- p2 + xlab(expression(paste('Treatment')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + scale_x_discrete(labels = c('Tree sites','Control sites'))
p2 <- p2 + geom_point(data = MyData.4,
                    aes(y = exp(MyData.4$eta), x = Treatment),
                    shape = 16, 
                    size = 12,
                    colour = "black",
                    alpha = 1)
p2 <- p2 + geom_errorbar(data = MyData.4,
                       aes(x = Treatment, 
                           ymax = exp(MyData.4$eta - 1.96 * MyData.4$SE), 
                           ymin = exp(MyData.4$eta + 1.96 * MyData.4$SE)), 
                       width=0.25, size = 0.8) + theme(axis.title.x = element_blank())
p2



################plot:abundance vs distreef###################################

require(rockchalk)

pframe <- data.frame(DistReef = HTrees1$DistReef,
                     Treatment = HTrees1$Treatment,
                     LocationID = HTrees1$LocationID)
pp <- predict(mod1, newdata =  pframe, allow.new.levels = TRUE, 
              type = "response", 
              se.fit = TRUE)
pframe$fit <- pp$fit
pframe$se.fit <- pp$se.fit
pframe$upr = pframe$fit+0.96*pframe$se.fit
pframe$lwr = pframe$fit-0.96*pframe$se.fit

library(ggplot2)
library(gridExtra)
library(tidyverse)
p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees1, 
                       aes(y = Abundance, x = DistReef),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + ggtitle("a") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("a"), axis.title.x = element_text("Distance to reef crest (m)"))
p2 <- p2 + ylab(expression(paste('a')))
p2 <- p2 + xlab(expression(paste('Distance to reef crest (m)')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_smooth(data= pframe,
                       method = "lm", aes(x = pframe$DistReef,
                                           y = pframe$fit))
p2

### this one doesnt give the right confidence interval! so:

#####################################################################################################################

MyData.4 <- data.frame(DistReef = HTrees1$DistReef,
                                  Treatment = HTrees1$Treatment,
                                  LocationID = HTrees1$LocationID)
summary(MyData.4)
X4 <- model.matrix(~Treatment + DistReef + LocationID, data = MyData.4)
betas4 <- fixef(mod1)$con
Covbetas4 <- vcov(mod1)$con
MyData.4$eta <- betas4 
mu4<-exp(MyData.4$eta) 
MyData.4$SE <- diag(Covbetas4)
MyData.4$upr = exp(MyData.4$eta - 1.96 * MyData.4$SE)
MyData.4$lwr = exp(MyData.4$eta + 1.96 * MyData.4$SE)

# create plot object with loess regression lines
g1 <- ggplot() + 
  stat_smooth(aes(x = pframe$DistReef, y = pframe$lwr), method = "lm", se = FALSE) +
  stat_smooth(aes(x = pframe$DistReef, y = pframe$upr), method = "lm", se = FALSE)
g1
# build plot object for rendering 
gg1 <- ggplot_build(g1)
# extract data for the loess lines from the 'data' slot
df2 <- data.frame(x = gg1$data[[1]]$x,
                  ymin = gg1$data[[1]]$y,
                  ymax = gg1$data[[2]]$y) 


### plot############
#####################

pal <- c("a.natural.tree" = "forestgreen", "b.control.plot" = "grey40")
pal
#colScale <- scale_colour_manual(name = "Treatment",values = c("forestgreen", "grey40"))
?scale_colour_manual


library(ggplot2)
library(gridExtra)
library(tidyverse)
p2 <- ggplot()
             
p2 <- p2 + geom_jitter(data = HTrees1, 
                       aes(y = Abundance, x = DistReef, fill = Treatment),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01 +
                       scale_fill_manual(values = pal))
                       
p2
p2 <- p2 + ggtitle("a") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("a"), axis.title.x = element_text("Distance to reef crest (m)"))
p2 <- p2 + ylab(expression(paste('a')))
p2 <- p2 + xlab(expression(paste('Distance to reef crest (m)')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_ribbon(data = df2, aes(x = x, ymin = ymin, ymax = ymax),
                       fill = "grey", alpha = 0.5)
p2 <- p2 + geom_smooth( method = "lm", aes(x = pframe$DistReef,
                           y = pframe$fit), color = "black", se = FALSE)
p2


#### better!

require(ggeffects)
require(ggiraph)
require(ggiraphExtra)
require(plyr)

dat1 <- ggpredict(mod1, interval = 'confidence', terms = c("Treatment"))
# dev.off()
plot(dat1, show_data = TRUE)

treatplot <- ggplot(dat1, aes(x = x, y = predicted)) +
  geom_jitter(data = filter(HTrees1, Treatment=="a.natural.tree"), aes(y = Abundance, x = Treatment), 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7, colour = "forestgreen") +
  geom_jitter(data = filter(HTrees1, Treatment=="b.control.plot"), aes(y = Abundance, x = Treatment), 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7, colour = "grey40") +
  geom_point(size = 6) +
  geom_errorbar( aes(ymin = conf.low, ymax = conf.high, color = NULL), width=0.2, size = 1,  alpha = 1) +
  theme_bw()
treatplot
