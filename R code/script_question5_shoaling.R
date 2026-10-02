# This subset only has "natural tree" (a) data 
# and is meant to answer if there is any relation to the tree perimeter 
# or to the distance or directionality 

###########################################################################################################
# Modelling Shoaling as a function of Treatment 
###########################################################################################################
# dev.off()


require(ggplot2)
require(rcompanion)
require(MASS)
require(lattice)
require(lmerTest)
require(afex)
###script: penguin book chapter presence-absence and proportional data, glm for presence-absence data

grouping <- read.table(file = "data/shoaling.only.natural.trees.txt",
                       header = TRUE,
                       dec = ".",
                       na.strings = "na")
str(grouping)
library(plyr)
grouping$Grouping <- revalue(grouping$Grouping, c("y"=1))
grouping$Grouping <- revalue(grouping$Grouping, c("n"=0))
grouping$Grouping <- as.factor(grouping$Grouping)


mod1 <- glm(Grouping ~ TreePerimeter + DistReef, family = binomial(), data = grouping)
summary(mod1)
plot(mod1)
## the patterns of the plots cannot be interpreted the same as usual because
## it is presence-absence data

plot(grouping$Grouping ~ grouping$TreePerimeter)

## this looks definitely non-linear

drop1(mod1)

op <- par(mfrow = c(2, 2), mar = c(4, 4, 2, 2))
plot(mod1, which = c(1), col = 1, add.smooth = FALSE,
     caption = "")
plot(grouping$TreePerimeter, resid(mod1), xlab = "TreePerimeter",
     ylab = "Residuals")
plot(grouping$DistReef, resid(mod1), xlab = "DistReef",
     ylab = "Residuals")
par(op)

### go for general additive model because of non-linear relationship

library(mgcv)
print(citation("mgcv"),
                     bibtex=TRUE)

group <- gam(Grouping ~ DistReef + s(TreePerimeter), family = binomial(), data = grouping, SE = TRUE)
summary(group)
anova(group)
plot(group)
gam.check(group)

# model variants of gam with different variables and smooth terms, compare

group1 <- gam(Grouping ~ TreePerimeter + s(DistReef), family = binomial(), data = grouping, SE = TRUE)
summary(group1)
plot(group1)
group2 <- gam(Grouping ~ s(TreePerimeter) + s(DistReef), family = binomial(), data = grouping, SE = TRUE)
summary(group2)
plot(group2)
group3 <- gam(Grouping ~ s(DistReef) + TreePerimeter, family = binomial(), data = grouping, SE = TRUE)
summary(group3)
plot(group3)
group4 <- gam(Grouping ~ s(DistReef) + s(TreePerimeter), family = binomial(), data = grouping, SE = TRUE)
summary(group4)
plot(group4)


AIC(group, group2, group1, group3, group4)
anova(group, group1, group2, group3, group4)

AICs <- AIC(group, group1, group2, group3, group4)
AICs
MyDF <- AICs[,1]
AICsNum <- AICs[,2]
minAW <- min(AICsNum)
Delta <- AICsNum - minAW
RL <- exp(-0.5 * Delta)
wi <- RL / sum(RL)
Z <- data.frame(MyDF, AICsNum, Delta, wi)
Z <- round(Z, digits = 3)
colnames(Z) <- c("DF", "AIC", "AIC differences", "Akaike weights")
Z

#### models with smooth term on both variables fit best
#### from this, create gamm with tree identifier "label" as random effect

groupc <- gamm(Grouping ~ s(DistReef) + s(TreePerimeter), 
              family = binomial(), data = grouping,  
              random = list(Label = ~1))
#not good, different smooth terms may be needed 
group5a <- gamm(Grouping ~ s(DistReef, bs="cc") + s(TreePerimeter, bs="ps"), 
               family = binomial(), data = grouping, 
               random = list(Label = ~1))
group5 <- gamm(Grouping ~ s(DistReef, bs="cc") + s(TreePerimeter, bs="cs"), 
     family = binomial(), data = grouping, 
     random = list(Label = ~1))
# was: cp, cs for treeperimeter. compare model fits
AICs <- AIC(group5a$lme, group5$lme)
AICs
plot(group5$gam)
summary(group5$gam)
gam.check(group5$gam)
group5$gam

### best fit achieved with smooth term of the class cyclic cubic regression splines 
#### and cyclic p-splines

plot(group5$gam, shade = TRUE)

### the gamm looks good
### plot predicted values: Grouping vs Treeperimeter
########


MyData <- data.frame(TreePerimeter = grouping$TreePerimeter)
group.pred <- predict(group5$gam, newdata = grouping, se.fit = TRUE, type = 'response')
MyData$fit <- group.pred$fit
MyData$se.fit <-group.pred$se.fit

library(ggplot2)
library(gridExtra)
library(ggformula)
p2 <- ggplot()
p2 <- p2 + geom_jitter(data = grouping,
                       aes(y = Grouping, x = TreePerimeter),
                       show.legend = FALSE,
                       size = 1,
                       shape = 16,
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + ggtitle("Grouping fish vs Tree Perimeter") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("Grouping fish"), axis.title.x = element_blank())
p2 <- p2 + ylab("Grouping fish")
p2 <- p2 + scale_y_discrete(labels = c('Absent','Present'))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_spline(data = MyData,
                       aes(y = exp(MyData$fit), x = TreePerimeter),
                       size = 0.5,
                       colour = "black",
                       alpha = 1/2)
p2



p3 <- ggplot ()
p3 <- p3 + stat_smooth(data = MyData, method = "loess", se = FALSE,
                       aes(x = TreePerimeter,
                           y = exp(MyData$fit) - 1.96 * MyData$se.fit),
                       size = 0.5,
                       colour = "grey",
                       alpha = 0.3)
p3 <-  p3 + geom_smooth(data = MyData, method = "loess", se = FALSE,
                        aes(x = TreePerimeter,
                            y = exp(MyData$fit) + 1.96 * MyData$se.fit),
                        size = 0.5,
                        colour = "grey",
                        alpha = 0.3)
p3

percentage_value <- grouping$MedGroupProb

gg1 <- ggplot_build(p3)
df2 <- data.frame(x = gg1$data[[1]]$x,
                  ymin = gg1$data[[1]]$y,
                  ymax = gg1$data[[2]]$y)
p3 <- p3 + geom_ribbon(data = df2, aes(x = x, ymin = ymin, ymax = ymax), fill = "grey",
                       alpha = 0.4)
p3


p4 <- ggplot()
p4 <- p4 + geom_jitter(data = grouping,
                       aes(y = Grouping, x = TreePerimeter),
                       show.legend = FALSE,
                       size = 5,
                       shape = 16,
                       height = 0.01,
                       width = 0.01, alpha = 0.4, color="forestgreen")
p4
p4 <- p4 + theme(axis.title.y = element_text("Grouping fish"), axis.title.x = element_text("Root system perimeter (m)"))
p4 <- p4 + ylab("Grouping fish")
p4 <- p4 + xlab("Root system perimeter")
p4 <- p4 + scale_y_discrete(labels = c('Absent','Present'))
p4 <- p4 + theme(text = element_text(size=2)) + theme_bw()

p4 <- p4 + geom_ribbon(data = df2, aes(x = x, ymin = ymin, ymax = ymax), fill = "grey",
                       alpha = 0.4)
p4 <- p4 + geom_smooth(data = MyData, method = "loess", se = FALSE,
                       aes(y = exp(MyData$fit), x = TreePerimeter),
                       size = 0.9,
                       alpha = 1/2, colour="black")
p4


# 
# ######################'''''''''##############
# ##################### plot model in relation to distance to reef
# #cc cyclic cubic regression spline 
# same model:
### plot predicted values
########


MyData2 <- data.frame(DistReef = grouping$DistReef)
group.pred2 <- predict(group5$gam, newdata = grouping, se.fit = TRUE, type = 'response')
MyData2$fit <- group.pred2$fit
MyData2$se.fit <-group.pred2$se.fit

library(ggplot2)
library(gridExtra)
library(ggformula)
p2 <- ggplot()
p2 <- p2 + geom_jitter(data = grouping,
                       aes(y = Grouping, x = DistReef),
                       show.legend = FALSE,
                       size = 1,
                       shape = 16,
                       height = 0.01,
                       width = 0.01)
p2
p2 <- p2 + ggtitle("Grouping fish vs Distance to reef crest") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("Grouping fish"), axis.title.x = element_blank())
p2 <- p2 + ylab("Grouping fish")
p2 <- p2 + scale_y_discrete(labels = c('Absent','Present'))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + geom_spline(data = MyData2,
                       aes(y = exp(MyData2$fit), x = DistReef),
                       size = 0.5,
                       colour = "black",
                       alpha = 1/2)
p2

# ?smooth.spline()
# 
# 
# #########
# 
# ######## but confidence interval is same everywhere
# ########alternative with self-buit SE Interval
# 
# #####


p3 <- ggplot ()
p3 <- p3 + stat_smooth(data = MyData2, method = "loess", se = FALSE,
                       aes(x = DistReef,
                           y = exp(MyData2$fit) - 1.96 * MyData2$se.fit),
                       size = 0.5,
                       colour = "grey",
                       alpha = 0.3)
p3 <-  p3 + geom_smooth(data = MyData2, method = "loess", se = FALSE,
                        aes(x = DistReef,
                            y = exp(MyData2$fit) + 1.96 * MyData2$se.fit),
                        size = 0.5,
                        colour = "grey",
                        alpha = 0.3)
p3

percentage_value <- grouping$MedGroupProb

gg2 <- ggplot_build(p3)
df3 <- data.frame(x = gg2$data[[1]]$x,
                  ymin = gg2$data[[1]]$y,
                  ymax = gg2$data[[2]]$y)
p3 <- p3 + geom_ribbon(data = df3, aes(x = x, ymin = ymin, ymax = ymax), fill = "grey",
                       alpha = 0.4)
p3


groupdist <- ggplot()
groupdist <- groupdist + geom_jitter(data = grouping,
                       aes(y = Grouping, x = DistReef),
                       show.legend = FALSE,
                       size = 5,
                       shape = 16,
                       height = 0.01,
                       width = 0.01, alpha = 0.4, colour = "forestgreen")
groupdist
groupdist <- groupdist + theme(axis.title.y = element_text("Grouping fish"), axis.title.x = element_text("Root system perimeter (m)"))
groupdist <- groupdist + ylab("Grouping fish")
groupdist <- groupdist + xlab("Distance to reef crest (m)")
groupdist <- groupdist + scale_y_discrete(labels = c('Absent','Present'))
groupdist <- groupdist + theme(text = element_text(size=2)) + theme_bw()

groupdist <- groupdist + geom_ribbon(data = df3, aes(x = x, ymin = ymin, ymax = ymax), fill = "grey",
                       alpha = 0.4)
groupdist <- groupdist + geom_smooth(data = MyData2, method = "loess", se = FALSE,
                       aes(y = exp(MyData2$fit), x = DistReef),
                       size = 0.9,
                       alpha = 1/2,
                       colour= "black")
groupdist


