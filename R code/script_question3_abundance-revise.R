# Questions with only mimics and real trees

rm(list=ls()) # cleaning memory

# Set working directory
#setwd("c:/")
library(lattice) # For fancy multipanel graphs
library(glmmTMB)
# source("HighstatLibV7.R") # Function created by Zuur et al; not included (copyrighted, Highland Statistics Ltd)

# Import the data 
HTrees4 <- read.table(file = "data/abundance.tree.control.mimic.new.txt",
                      header = TRUE,
                      dec = ".",
                      stringsAsFactors = TRUE) # the default before R 4.0; pairs() below needs Aspect as a factor
# explore the variables
names(HTrees4)

str(HTrees4)

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
boxplot(HTrees4$Abundance, 
        main = "Abundance")
dotchart(HTrees4$Abundance, 
         xlab = "Range of data", 
         ylab = "Values")
# all good
str(HTrees4)
pairs(HTrees4[,c("Lat","Long","Aspect","Trees50", 
                 "DistIsland", "DistReef", "WMI")])
#      lower.panel = panel.cor) # panel.cor is from HighstatLibV7.R, not included (copyrighted)
# Lat cant go with Long
# Lat cant go with Trees50
# Lat cant go with DistIsland
# Lat shouldnt go with DistReef
# Long cant go with Trees50
# Long cant go with DistIsland
# Trees50 cant go with DistIsland

# Collinearity of everything with Aspect:
boxplot(Lat ~ factor(Aspect),
        ylab = "Lat",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear
boxplot(Long ~ factor(Aspect),
        ylab = "Long",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear
boxplot(Trees50 ~ factor(Aspect),
        ylab = "Trees50",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear
boxplot(DistIsland ~ factor(Aspect),
        ylab = "DistIsland",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear
boxplot(DistReef ~ factor(Aspect),
        ylab = "DistReef",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear
boxplot(WMI ~ factor(Aspect),
        ylab = "WMI",
        xlab = "Aspect",
        data = HTrees4)
# Not colinear

# Collinearity of everything with Treatment
boxplot(Lat ~ factor(Treatment),
        ylab = "Lat",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear
boxplot(Long ~ factor(Treatment),
        ylab = "Long",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear
boxplot(Trees50 ~ factor(Treatment),
        ylab = "Trees50",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear
boxplot(DistIsland ~ factor(Treatment),
        ylab = "DistIsland",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear
boxplot(DistReef ~ factor(Treatment),
        ylab = "DistReef",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear
boxplot(WMI ~ factor(Treatment),
        ylab = "WMI",
        xlab = "Treatment",
        data = HTrees4)
# Not colinear

MyVar <- c("Lat","Long", "Aspect", "Trees50", "DistIsland", "DistReef", "WMI", "Abundance")
pairs(HTrees4[, MyVar])
#      lower.panel = panel.cor) # panel.cor is from HighstatLibV7.R, not included (copyrighted)
# Abundance seems strongly negatively related to Latitude (or Tree50 or DistIsland)

boxplot(Abundance ~ factor(Aspect), 
        data = HTrees4,
        varwidth = TRUE,
        ylab = "Fish abundance",
        xlab = "Aspect",
        main = "")

boxplot(Abundance ~ factor(Treatment), 
        data = HTrees4,
        varwidth = TRUE,
        ylab = "Fish abundance",
        xlab = "Treatment",
        main = "")

# Suspected interactions?
par(mfrow = c(1,2), mar = c(5,5,2,2))
boxplot(Abundance[Treatment=="a.real.tree"] ~ Aspect[Treatment=="a.real.tree"], 
        ylab = "Number of fish",
        main = "Natural Trees", 
        las=1, 
        data=HTrees4)
boxplot(Abundance[Treatment=="c.mimic"] ~ Aspect[Treatment=="c.mimic"], 
        ylab = "Number of fish",
        main = "Mimic Trees", 
        las=1, 
        data=HTrees4)
# Apparent interaction - there seems to be a difference between aspects in natural but not in mimic trees
# worth testing the interaction. However I cannot include the interaction in the model because of the NAs I think
# Worth trying this in a dataset including only Natural and Mimic Trees


xyplot(Abundance ~ Trees50 | factor(Treatment), 
       xlab = list("Trees50 (unit?)", cex = 1.5),
       ylab = list("Number of fish", cex = 1.5),
       data = HTrees4, layout = c(2,1),
       type = "p", col = 1, pch = 16,
       strip = strip.custom(bg = 'white',
                            par.strip.text = list(cex = 1.2)),
       scales = list(alternating = F,
                     x = list(relation = "same"),
                     y = list(relation = "same")))
# Clear positive relationship between Trees50 and Number of fish (for real trees)
# Not as clear with mimics

xyplot(Abundance ~ WMI | factor(Treatment), 
       xlab = list("WMI", cex = 1.5),
       ylab = list("Number of fish", cex = 1.5),
       data = HTrees4, layout = c(2,1),
       type = "p", col = 1, pch = 16,
       strip = strip.custom(bg = 'white',
                            par.strip.text = list(cex = 1.2)),
       scales = list(alternating = F,
                     x = list(relation = "same"),
                     y = list(relation = "same")))
# Not aparent interaction between WMI and treatment, there is not a strong
# relationship between fish and WMI for mimics or for real tree
library(glmmTMB)
mod4 <- glmmTMB(Abundance ~ Treatment + Aspect + Treatment:Aspect + Trees50 + Trees50:Treatment 
                + WMI + DistReef  
                + (1 | LocationID),
                family = poisson,
                data = HTrees4)
summary(mod4)

# model checks and validation:
E1 <- resid(mod4, type = "pearson")
F1 <- fitted(mod4)
eta <- predict(mod4, type = "link")
par(mfrow = c(3,3), mar = c(5,5,2,2))
plot(x = F1, 
     y = E1,
     xlab = "Fitted values",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h = 0, v = 0, lty = 2)
# heterogeneity

plot(x = eta, 
     y = E1,
     xlab = "Eta",
     ylab = "Pearson residuals",
     cex.lab = 1.5)
abline(h=0, v = 0, lty = 2)
# not too bad a little heterogeneity - this is not new, variance differs among treatments. 
# discuss in thesis.

boxplot(E1 ~ Treatment, 
        ylab = "Pearson residuals",
        data = HTrees4,
        cex.lab = 1.5, 
        xlab = "Treatment")
abline(h = 0, v = 0, lty = 2)
# ok

plot(x = HTrees4$Trees50, 
     y = E1,
     xlab = "Trees50 (unit)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# Errors not so independent from Trees50

plot(x = HTrees4$DistReef, 
     y = E1,
     xlab = "Distrance from Reef (km)",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

plot(x = HTrees4$WMI, 
     y = E1,
     xlab = "Water Motion Index",
     ylab = "Pearson residuals",
     cex.lab = 1.5,
     pch = 16)
abline(h=0, v = 0, lty = 2)
# ok

# Checking for spatial autocorrelation of residuals:
ai <- ranef(mod4)$cond$LocationID$`(Intercept)`
MyData = data.frame(ai = ai,
                    Lat = tapply(HTrees4$Lat, FUN = mean, INDEX = HTrees4$LocationID),
                    Lon = tapply(HTrees4$Long, FUN = mean, INDEX = HTrees4$LocationID))
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
# random effects for Location appear to be spatially un-correlated. 

# Overdispersion
E1 <- resid(mod4, type = "pearson")
N  <- nrow(HTrees4)
p  <- length(fixef(mod4)) + 1
Overdispersion <- sum(E1^2) / (N - p)
Overdispersion
# Not bad!

# But for now
drop1(mod4, test = "Chi")
# too many warnings, perhaps this means we cannot test that many interactions and main terms in the model
# since we need to test the interactions, we do it in separate models

# Interaction Treatment:Aspect
library(glmmTMB)
mod5 <- glmmTMB(Abundance ~ Treatment + Aspect + Treatment:Aspect
                + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
summary(mod5)
drop1(mod5, test = "Chi")
# no significant effect of the interaction

mod6 <- glmmTMB(Abundance ~ Treatment + Aspect +
                + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
summary(mod6)
# Effect of treatment, no effect of aspect


# Interaction Treatment:Aspect
mod7 <- glmmTMB(Abundance ~ Treatment + Trees50 + Treatment:Trees50 +
                  + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
summary(mod7)
drop1(mod7, test = "Chi")
# no effect of the interaction

mod8 <- glmmTMB(Abundance ~ Treatment + Trees50 
                  + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
drop1(mod8, test = "Chi")
# no effect of Trees50

mod9 <- glmmTMB(Abundance ~ Treatment  
                + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
summary(mod9)
drop1(mod9, test = "Chi")
# Significant effect of treatment (as we knew from previous one)

# Interaction Treatment:WMI
mod10 <- glmmTMB(Abundance ~ Treatment + WMI + Treatment:WMI 
                  + (1 | LocationID),
                family = nbinom1(),
                data = HTrees4)
summary(mod10)
drop1(mod10, test = "Chi")
# no effect of interaction

mod11 <- glmmTMB(Abundance ~ Treatment + WMI 
                   + (1 | LocationID),
                 family = nbinom1(),
                 data = HTrees4)
drop1(mod11, test = "Chi")
# no effect of WMI only of treatment

mod <- glmmTMB(Abundance ~ Treatment
                 + (1 | LocationID),
                 family = nbinom1(),
                 data = HTrees4)
summary(mod)
drop1(mod11, test = "Chi")
# no effect
#######################
######################### plot #############################
########################
HTrees4$Treatment <- as.factor(HTrees4$Treatment)

pframe <- data.frame(Treatment = levels(HTrees4$Treatment),
                     LocationID = mean(HTrees4$LocationID))
str(pframe)

pframe
pp <- predict(mod, newdata =  pframe, allow.new.levels = TRUE, 
              type = "response", 
              se.fit = TRUE)
pframe$fit <- pp$fit
pframe$se.fit <- pp$se.fit
#####################################################################################################################
library(lattice)
library(ggplot2)
library(gridExtra)
str(HTrees4)
HTrees4$Abundance <- as.numeric(HTrees4$Abundance)
HTrees4$Treatment <- factor(HTrees4$Treatment, levels=c("a.real.tree", "c.mimic", "b.control.plot"))

p2 <- ggplot()
pal <- c("forestgreen", "steelblue3", "grey40")
#level_order <- c('')

p2 <- ggplot()
p2 <- p2 + geom_jitter(data = HTrees4, 
                       aes(y = Abundance, x = Treatment, color = Treatment),
                       show.legend = FALSE,
                       size = 6,
                       shape = 16, 
                       height = 0.01,
                       width = 0.01,
                       alpha = 0.8) + scale_color_manual(values = pal)
p2
p2 <- p2 + ggtitle("Fish Abundance vs treatment") + theme(plot.title = element_text(hjust=0.5, size = 7))
p2 <- p2 + theme(axis.title.y = element_text("Number of fish"), axis.title.x = element_text("Treatment"))
p2 <- p2 + xlab(expression(paste('treatment')))
p2 <- p2 + theme(text = element_text(size=2)) + theme_bw()
p2 <- p2 + scale_x_discrete(labels = c('Tree sites (small)','Mimic sites', 'Control sites'))
p2 <- p2 + geom_point(data = pframe,
                      aes(y = pframe$fit, x = Treatment),
                      shape = 16, 
                      size = 12,
                      colour = "black",
                      alpha = 1)
p2 <- p2 + geom_errorbar(data = pframe,
                         aes(x = Treatment, 
                             ymax = pframe$fit - 1.96 * pframe$se.fit, 
                             ymin = pframe$fit + 1.96 * pframe$se.fit), 
                         width=0.25, size = 0.8) + theme(axis.title.x = element_blank())
p2


### new for paper

require(ggeffects)
require(ggiraph)
require(ggiraphExtra)
require(plyr)
library(dplyr)


# Get predicted values with confidence intervals
dat5 <- ggpredict(mod, interval = 'confidence', terms = c("Treatment"))

# Check the structure of dat5
print("Structure of dat5:")
print(str(dat5))

# Check the structure of HTrees4
print("Structure of HTrees4:")
print(str(HTrees4))

# Plot the ggpredict output
plot(dat5, show_data = TRUE)

# Ensure Treatment is a factor in HTrees4
HTrees4$Treatment <- as.factor(HTrees4$Treatment)

# Create a plot using ggplot2
treatplot2 <- ggplot(dat5, aes(x = x, y = predicted)) +
  geom_jitter(data = filter(HTrees4, Treatment == "c.mimic"), 
              aes(y = Abundance, x = Treatment), 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7, colour = "steelblue3") +
  geom_jitter(data = filter(HTrees4, Treatment == "a.real.tree"), 
              aes(y = Abundance, x = Treatment), 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7, colour = "forestgreen") +
  geom_jitter(data = filter(HTrees4, Treatment == "b.control.plot"), 
              aes(y = Abundance, x = Treatment), 
              size = 4, height = 0.01, width = 0.1, alpha = 0.7, colour = "grey40") +
  geom_point(size = 6) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, size = 1, alpha = 1) +
  theme_bw()

print(treatplot2)

summary(mod)
