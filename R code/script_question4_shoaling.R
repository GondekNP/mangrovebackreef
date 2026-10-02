# The first subsets only have the treatments "natural tree" (a) and "control" (b). 
# This subset is meant to answer if the trees themselves have an effect 
# (Shoaling ~ Treatment).

###########################################################################################################
# Modelling Shoaling as a function of Treatment 
###########################################################################################################
# dev.off()

#setwd()
require(ggplot2)
require(rcompanion)
require(MASS)
require(lattice)

grouping <- read.table(file = "data/shoaling.tree.and.controls.txt",
                       header = TRUE,
                       dec = ".",
                       na.strings = "na")

# look at data and revalue or transform as needed

str(grouping)
grouping$Label <- as.factor(grouping$Label)
library(plyr)
grouping$Grouping <- revalue(grouping$Grouping, c("y"=1))
grouping$Grouping <- revalue(grouping$Grouping, c("n"=0))
grouping$Grouping <- as.factor(grouping$Grouping)
str(grouping)
grouping$Treatment <- as.factor(grouping$Treatment)

# take a first look

plot(grouping$Grouping ~ grouping$Treatment)

# trying and comparing different glm approaches, look at diagnostic plot etc

group1 <- glm(Grouping ~ Treatment,  data = grouping, family = binomial)
summary(group1)
plot(group1)

xytab <- table(grouping$Treatment, grouping$Grouping)
xytab

xfactor = factor(c("a","b"))
xfactor

group2=glm(xytab~xfactor, family = binomial("logit"))
group2
summary(group2)
# plot(group2) # errors: model is fitted to only 2 rows

group3 <- glm(Grouping ~ 1 + Treatment, data = grouping, family = binomial)
summary(group3)
plot(group3)

anova(group1)
anova(group2)
anova(group3)

#these approaches don't seem to work, opt for glmer

require(nlme)
require(lme4)
require(MASS)

group4 <- glmer(Grouping ~ Treatment + DistReef + (1|SiteID), 
              family = binomial, data = grouping, nAGQ = 50)
summary(group4)
str(grouping)


# error message...rescale?
# Standardize the numerical predictor variables

grouping$standardized_DistReef <- scale(grouping$DistReef)

# Fit the glmer model with standardized predictors
group_stand <- glmer(Grouping ~ Treatment + standardized_DistReef + (1|SiteID), 
              family = binomial, data = grouping, nAGQ = 50)
summary(group_stand)


# better, but check model diagnostics (resid vs fitted, collinearity)

plot(group_stand)
library(car)
vif(group_stand) 

# all good, extract some model stats for plotting

require(tidyverse)
require(ggeffects)

ggemmeans(group_stand, terms = "Treatment") %>% plot() 

# but looking at confidence intervals from this model with ggemmeans there seems to be a separation issue
# this can be avoided using this approach (also a GLMM but bayesian frame can deal with separation issue)

require(blme)
group_bayes <- blme::bglmer(Grouping ~ Treatment * standardized_DistReef + (1|SiteID),
                                  data = grouping,
                                  family = binomial, 
                                  fixef.prior = normal(sd = c(10, 2.5)))

model_emm <- emmeans::emmeans(group_bayes, specs = "Treatment",
                                      type = "response")
# Note is OK to ignore
# put in dataframe and merge with complete data, also need a numerical value for Grouping variable

modstats = as.data.frame(summary(model_emm))
modstats

grouping$Groupingnum <- as.numeric(grouping$Grouping)-1

data.mer <- merge(modstats, grouping, by.x = "Treatment", by.y = "Treatment")


plot7 <- ggplot(data.mer, aes(x = Treatment, y = prob, fill=factor(Groupingnum))) +
  scale_fill_manual("Groupingnum", values = c("NA", "forestgreen", "grey40"))+
  geom_bar(data = filter(data.mer, Treatment=="a"), stat='identity', position = "fill", width = 0.5, alpha=0.5, size = 1) +
  geom_bar(data = filter(data.mer, Treatment=="b"), stat='identity', position = "fill", width = 0.5, alpha=0.5) +
  geom_point(size = 6, color="black") +
  geom_errorbar(aes(ymin=asymp.LCL, ymax=asymp.UCL), color = "black", width=0.2, size=1, alpha=1)+
  theme_bw()+
  theme(legend.position = "none")
plot7

#all good