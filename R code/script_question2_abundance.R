# The second subset only have the treatment "natural tree" (a) 
# and is meant to answer if there is any relation to the tree perimeter 
# or to the distance or directionality 

###########################################################################################################
# Modelling Fish abundance as a function of tree perimeter, aspect, and others
###########################################################################################################

# dev.off()
rm(list=ls()) # cleaning memory

# Set working directory
#setwd("~/mangrove paper/fish focus/data and scripts")

# Import the data 
HTrees2 <- read.table(file = "data/abundance.only.natural.trees.txt",
                    header = TRUE,
                    dec = ".")

library(lattice)  # For fancy multipanel graphs
# source("HighstatLibV7.R") # Function created by Zuur et al; not included (copyrighted, Highland Statistics Ltd)

# explore the variables
names(HTrees2)

# Check how R is reading these variables (factors or numbers)
str(HTrees2)

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
boxplot(HTrees2$Abundance, 
        main = "Abundance")
dotchart(HTrees2$Abundance, 
         xlab = "Range of data", 
         ylab = "Values")
# Worrysome outliers would be points sticking out a lot more fro the rest, 
# there are no important ones to worry about here. 

#B Collinearity among predictors
pairs(HTrees2[,c("TreePerimeter","Lat","Long", "DistIsland", 
                "DistReef", "Trees50", "WMI")])
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

boxplot(TreePerimeter ~ factor(Aspect), 
        data = HTrees2,
        ylab = "TreePerimeter",
        xlab = "Aspect")
# Not colinear
boxplot(Lat ~ factor(Aspect),
        ylab = "Lat",
        xlab = "Aspect",
        data = HTrees2)
# Not colinear
boxplot(Long ~ factor(Aspect),
        ylab = "Long",
        xlab = "Aspect",
        data = HTrees2)
# Not colinear
boxplot(Trees50 ~ factor(Aspect),
        ylab = "Trees50",
        xlab = "Aspect",
        data = HTrees2)
# Not colinear
boxplot(DistIsland ~ factor(Aspect),
        ylab = "DistIsland",
        xlab = "Aspect",
        data = HTrees2)
# Not colinear
boxplot(DistReef ~ factor(Aspect),
        ylab = "DistReef",
        xlab = "Aspect",
        data = HTrees2)
# Not colinear
boxplot(WMI ~ factor(Aspect),
        ylab = "WMI",
        xlab = "Aspect",
        data = HTrees2)
# e and s are a little more different from each other in WMI but not enough to be considered colinear

#C. Initial inspection of relationships Y vs X
MyVar <- c("TreePerimeter","Lat","Long", "DistIsland", 
           "DistReef", "Trees50", "WMI", "Abundance")
pairs(HTrees2[, MyVar])
#      lower.panel = panel.cor) # panel.cor is from HighstatLibV7.R, not included (copyrighted)
# Abundance seems positively related to Tree Perimeter 
# Abundance seems negatively but less strongly related to WMI
# unnaffected by all other parameters

boxplot(Abundance ~ factor(Aspect), 
        data = HTrees2,
        varwidth = TRUE,
        ylab = "Fish abundance",
        xlab = "Aspect",
        main = "")
# not an apparent effect of aspect on fish abundance

# Suspected interactions?
xyplot(Abundance ~ TreePerimeter | factor(Aspect), 
       xlab = list("Tree Perimter (m)", cex = 1.5),
       ylab = list("Number of fish", cex = 1.5),
       data = HTrees2, layout = c(2,1),
       type = "p", col = 1, pch = 16,
       strip = strip.custom(bg = 'white',
                            par.strip.text = list(cex = 1.2)),
       scales = list(alternating = F,
                     x = list(relation = "same"),
                     y = list(relation = "same"))
)
# The relationship of abundance with perimeter seems to be slightly different between aspects
# which is perhaps only due to the largest schools showing up on the exposed sites
# Perhaps worth including this interaction in the model. 

#F. Zero inflation
sum(HTrees2$Abundance == 0)
sum(HTrees2$Abundance == 0) / nrow(HTrees2)
plot(table(HTrees2$Abundance)) 
# Not zero inflated

#G. Are categorical covariates balanced?
table(HTrees2$Aspect)
plot(table(HTrees2$Aspect), 
     type = "h",
     xlab = "Aspect values",
     ylab = "Number of observations per category")
# Yes

# Model:
# (1) Abundance is currently a count so you need a glm (Poisson distribution)
# If this changes to a density (somehow computing the area surveyed) then you can use an lm 
# (2) As predictors we need to include all non-colinear variables and when two are strongly colinear 
# with each other, we include only one of them and explain that a significant effect could be
# attributed to one or the other. 
# (3) We know there may be some dependency among trees of the same LocationID


# Options for models:

# Option 1. Start simplest with GLM with Poisson distribution (because abundance is a count) 
# "ignoring" the dependency among trees within each location
mod1 <-glm(Abundance ~ TreePerimeter + Aspect + DistIsland + DistReef + WMI + TreePerimeter:Aspect, 
           family = poisson,
           data = HTrees2)
summary(mod1)

# dev.off()
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

plot(x = eta, 
     y = E1,
     xlab = "Eta",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h=0, v = 0, lty = 2)
# This is the most problematic plot shows Pearson residuals are not independent from ETA

plot(x = HTrees2$TreePerimeter, 
     y = E1,
     xlab = "Tree Perimeter (m)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)

boxplot(E1 ~ Aspect, 
        ylab = "Pearson residuals",
        data = HTrees2,
        cex.lab = 1.5, 
        xlab = "Aspect")
abline(h = 0, v = 0, lty = 2)

plot(x = HTrees2$DistIsland, 
     y = E1,
     xlab = "Distrance from Island (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)

plot(x = HTrees2$DistReef, 
     y = E1,
     xlab = "Distrance from Island (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)

plot(x = HTrees2$WMI, 
     y = E1,
     xlab = "Water Motion Index",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)

# Plus, there is overdispersion:
dp<-sum(residuals(mod1,type="pearson")^2)/mod1$df.res
dp


# Option 2.Lets try to incorporate that dependence between trees in a location:
library(glmmTMB)
citation("glmmTMB")
mod2 <- glmmTMB(Abundance ~ TreePerimeter + Aspect + DistReef
                   + (1 | LocationID),
                family = nbinom1(),
                data = HTrees2)
summary(mod2)
require(car)
Anova(mod2)

# model checks and validation:
E1 <- resid(mod2, type = "pearson")
F1 <- fitted(mod2)
eta <- predict(mod2, type = "link")

plot(x = F1, 
     y = E1,
     xlab = "Fitted values",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h = 0, v = 0, lty = 2)
# better than before

plot(x = eta, 
     y = E1,
     xlab = "Eta",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h=0, v = 0, lty = 2)
# This plot improved the dependency situation

plot(x = HTrees2$TreePerimeter, 
     y = E1,
     xlab = "Tree Perimeter (m)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

boxplot(E1 ~ Aspect, 
        ylab = "Pearson residuals",
        data = HTrees2,
        cex.lab = 1.5, 
        xlab = "Aspect")
abline(h = 0, v = 0, lty = 2)
# ok

plot(x = HTrees2$DistIsland, 
     y = E1,
     xlab = "Distrance from Island (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

plot(x = HTrees2$DistReef, 
     y = E1,
     xlab = "Distrance from Island (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok 

plot(x = HTrees2$WMI, 
     y = E1,
     xlab = "Water Motion Index",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

# Checking for spatial autocorrelation of residuals:
ai <- ranef(mod2)$cond$LocationID$`(Intercept)`
MyData = data.frame(ai = ai,
                    Lat = tapply(HTrees2$Lat, FUN = mean, INDEX = HTrees2$LocationID),
                    Lon = tapply(HTrees2$Long, FUN = mean, INDEX = HTrees2$LocationID))
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
# Random effects for Location, spatially un-correlated.

# Overdispersion before dropping variables
E1 <- resid(mod2, type = "pearson")
N  <- nrow(HTrees2)
p  <- length(fixef(mod2)) + 1
Overdispersion <- sum(E1^2) / (N - p)
Overdispersion

# improvement of the model validation plots, we trust the model and:
drop1(mod2, test = "Chi")
# according to this model abundance is strongly related to: 
# Tree perimeter, Aspect and their interaction
# Dist Island, 
# Dist Reef.

#  plot the observed values: 
#
#
xyplot(Abundance ~ TreePerimeter | factor(Aspect), 
       xlab = list("Tree Perimter (m)", cex = 1.5),
       ylab = list("Number of fish", cex = 1.5),
       data = HTrees2, layout = c(2,1),
       type = "p", col = 1, pch = 16,
       strip = strip.custom(bg = 'white',
                            par.strip.text = list(cex = 1.2)),
       scales = list(alternating = F,
                     x = list(relation = "same"),
                     y = list(relation = "same")))

# "sketching fitted values" codes of Zuur et al 
# to fit lines with a ribbon for confidence intervals. 

pp <- predict(mod2, type = "response", SE = TRUE)
pframe <- data.frame(TreePerimeter= HTrees2$TreePerimeter,
                     Aspect = HTrees2$Aspect, pp)
library(ggplot2)
citation("ggplot2")
p1 <- ggplot(data=HTrees2, 
             aes(x=TreePerimeter, y=Abundance)) + 
  geom_point(aes(size = 6),  colour = "forestgreen") +
  theme(text = element_text(size=2)) + theme_bw() +
  scale_x_continuous("Root system perimeter (m)") +
  scale_y_continuous("Abundance") + 
  facet_wrap(.~Aspect ) 
p1
p1 <- p1 + stat_smooth(data = pframe, method = "lm",
                       aes(x = TreePerimeter, y = pframe$pp, ), colour = "black") 
p1
#####################
###############################
##separate:abundance vs aspect
####
#####

pframe <- data.frame(Aspect =HTrees2$Aspect,
                     DistReef = mean(HTrees2$DistReef),
                     TreePerimeter = mean(HTrees2$TreePerimeter),
                     LocationID = mean(HTrees2$LocationID))
pframe
pp <- predict(mod2, newdata =  pframe, allow.new.levels = TRUE, 
              type = "response", 
              se.fit = TRUE)
pframe$fit <- pp$fit
pframe$se.fit <- pp$se.fit



### plotting script ####
#####################################################################################################################
library(lattice)
library(ggplot2)
library(gridExtra)
str(HTrees2)
HTrees2$Abundance <- as.numeric(HTrees2$Abundance)

p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees2, 
                       aes(y = Abundance, x = Aspect),
                       show.legend = FALSE,
                       colour = "forestgreen",
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01,
                       alpha = 0.9)
p2
p2 <- p2 + ggtitle("Fish Abundance vs Aspect") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("Abundance"), axis.title.x = element_text("Treatment"))
p2 <- p2 + xlab(expression(paste('Aspect')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + scale_x_discrete(labels = c('exposed','sheltered'))
p2 <- p2 + geom_point(data = pframe,
                      aes(y = pframe$fit, x = Aspect),
                      shape = 16, 
                      size = 12,
                      colour = "black",
                      alpha = 1)
p2 <- p2 + geom_errorbar(data = pframe,
                         aes(x = Aspect, 
                             ymax = pframe$fit - 1.96 * pframe$se.fit, 
                             ymin = pframe$fit + 1.96 * pframe$se.fit), 
                         width=0.25, size = 0.8) + theme(axis.title.x = element_blank())
p2


############################################################
################################

##plot3 ##### distreef
require(rockchalk)
pframe <- data.frame(DistReef = HTrees2$DistReef,
                     TreePerimeter = HTrees2$TreePerimeter,
                     LocationID = HTrees2$LocationID,
                     Aspect = HTrees2$Aspect)
pp <- predict(mod2, newdata =  pframe, allow.new.levels = TRUE, 
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
p2 <- p2 + geom_jitter(data = HTrees2, 
                       aes(y = Abundance, x = DistReef, colour = "forestgreen"),
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

### confidence interval doesnt look right
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
colors()
library(ggplot2)
library(gridExtra)
library(tidyverse)
p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees2, 
                       aes(y = Abundance, x = DistReef, color= "forestgreen"),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + scale_color_identity()
p2
p2 <- p2 + ggtitle("a") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("a"), axis.title.x = element_text("Distance to reef crest (m)"))
p2 <- p2 + ylab(expression(paste('a')))
p2 <- p2 + xlab(expression(paste('Distance to reef crest (m)')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_ribbon(data = df2, aes(x = x, ymin = ymin, ymax = ymax),
                       fill = "grey", alpha = 0.5)
p2 <- p2 + geom_smooth( method = "lm", aes(x = pframe$DistReef,
                                           y = pframe$fit), se = FALSE, colour ='black')
p2


###better

#######################################
################## plot 4
# abundance vs treeperimeter


pframe <- data.frame(DistReef = HTrees2$DistReef,
                     TreePerimeter = HTrees2$TreePerimeter,
                     LocationID = HTrees2$LocationID,
                     Aspect = HTrees2$Aspect)
pp <- predict(mod2, newdata =  pframe, allow.new.levels = TRUE, 
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
p2 <- p2 + geom_jitter(data = HTrees2, 
                       aes(y = Abundance, x = TreePerimeter),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + ggtitle("a") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("a"), axis.title.x = element_text("Distance to reef crest (m)"))
p2 <- p2 + ylab(expression(paste('a')))
p2 <- p2 + xlab(expression(paste('Tree perimeter (m)')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_smooth(data= pframe,
                       method = "lm", aes(x = pframe$TreePerimeter,
                                          y = pframe$fit))
p2

# same issue with confidence intervals
# create plot object with loess regression lines
g1 <- ggplot() + 
  stat_smooth(aes(x = pframe$TreePerimeter, y = pframe$lwr), method = "lm", se = FALSE) +
  stat_smooth(aes(x = pframe$TreePerimeter, y = pframe$upr), method = "lm", se = FALSE)
g1
# build plot object for rendering 
gg1 <- ggplot_build(g1)
# extract data for the loess lines from the 'data' slot
df2 <- data.frame(x = gg1$data[[1]]$x,
                  ymin = gg1$data[[1]]$y,
                  ymax = gg1$data[[2]]$y) 
### plot############
#####################

library(ggplot2)
library(gridExtra)
library(tidyverse)
p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees2, 
                       aes(y = Abundance, x = TreePerimeter, color= "forestgreen"),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + scale_color_identity()
p2
p2 <- p2 + ggtitle("a") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("a"), axis.title.x = element_text("Distance to reef crest (m)"))
p2 <- p2 + ylab(expression(paste('a')))
p2 <- p2 + xlab(expression(paste('Tree perimeter (m)')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_ribbon(data = df2, aes(x = x, ymin = ymin, ymax = ymax),
                       fill = "grey", alpha = 0.5)
p2 <- p2 + geom_smooth( method = "lm", aes(x = pframe$TreePerimeter,
                                           y = pframe$fit), se = FALSE, colour='black')
p2


### better



################## MUCH easier way to plot all variables in mod2:

require(ggeffects)
require(ggiraph)
require(ggiraphExtra)
require(plyr)
dat1 <- ggpredict(mod2, interval = "confidence", terms = c("TreePerimeter"))

periplot <- ggplot(dat1, aes(x = x, y = predicted)) +
  geom_line(size = 1) +
  geom_ribbon( aes(ymin = conf.low, ymax = conf.high, color = NULL), alpha = .15) +
  geom_point(data = HTrees2, aes(y = Abundance, x = TreePerimeter), colour = "forestgreen", 
             size = 4, alpha = 0.7) +
  theme_bw()
periplot

dat2 <- ggpredict(mod2, interval = "confidence", terms = c("Aspect"))
plot(dat2, show_data = TRUE)

aspectplot <- ggplot(dat2, aes(x = x, y = predicted)) +
  geom_jitter(data = HTrees2, aes(y = Abundance, x = Aspect), colour = "forestgreen", 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7) +
  geom_point(size = 6) +
  geom_errorbar( aes(ymin = conf.low, ymax = conf.high, color = NULL), width=0.2, size = 1,  alpha = 1) +
  theme_bw()
aspectplot

dat3 <- ggpredict(mod2, interval = "confidence", terms = c("DistReef"))

distplot <- ggplot(dat3, aes(x = x, y = predicted)) +
  geom_line(size = 1) +
  geom_ribbon( aes(ymin = conf.low, ymax = conf.high, color = NULL), alpha = .15) +
  geom_point(data = HTrees2, aes(y = Abundance, x = DistReef), colour = "forestgreen", 
             size = 4, alpha = 0.7) +
  theme_bw()
distplot


require(sjPlot)
plot_model(mod2, type = "pred", show.data = TRUE)
