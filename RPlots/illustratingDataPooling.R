### Creates Plot from Introduction
library(tidyverse)
library(ggplot2)
library(forcats)
library(latex2exp)
library(stringr)
library(extrafont)
loadfonts()

library(showtext)
font_add("Times New Roman", "Times New Roman.ttf")
showtext_auto()

#pink, blue, green
cbPallette = c("#FBBEBA", "#B5CEFF", "#9ADDA5")

#first is teal, then pink, 
cbPallette2 = c("#00AFBD", "#FBBEBA")

#dat = read_csv("../Results/InformsPlots/singleKUnifNewsvendor_1000_1000.csv")
dat = read_csv("../Results/singleKUnifNewsvendor_1000_1000.csv")

##add pretty labels
dat <- dat %>% mutate(Method = factor(Method), 
                      Label = fct_recode(Method, 'Shrunken-SAA'="LOO_avg"), 
                      Label = fct_relevel(Label, "FullInfo", "SAA", "Oracle", 'Shrunken-SAA', "LOO_unif"))

dat.sum<- dat %>% group_by(Label) %>%
  summarise(avg = mean(TruePerf), 
            std = sd(TruePerf), 
            avgAlpha0 = mean(alpha))

g <- dat %>% filter(Method %in% c("SAA", "LOO_avg")) %>%
  ggplot(aes(x=TruePerf, group=Label, fill=Label)) + 
  geom_histogram(size=0, binwidth = .01) 

#add lines for means
g<- g + 
  geom_vline(data = filter(dat.sum, Label %in% c("FullInfo", "SAA", 'Shrunken-SAA')),  
             aes(xintercept=avg, linetype=Label)) 
g <- 
  g + theme_minimal(base_family = "Times New Roman", base_size=10) + 
  theme(legend.title=element_blank(), 
        legend.position=c(.5, .85)) + 
  ylab("") + xlab("Cost") + 
  scale_fill_manual(values = cbPallette2) + 
  scale_linetype_manual(values=c("dotted", "dotted", "dotted"), guide="none") + 
  xlim(4.3, 5.02)

#### Try to annotate with arrows and percentages
#### These values are hardcoded from the dat.sum table
full_info = as.double(dat.sum %>% filter(Label=="FullInfo") %>% select(avg))
shrunk = as.double(dat.sum %>% filter(Label=='Shrunken-SAA') %>% select(avg))
saa = as.double(dat.sum %>% filter(Label=="SAA") %>% select(avg))

g <- g + annotate("text", x=(full_info + shrunk)/2, y=250, label="2.5%", 
             family="Times New Roman", size=3, vjust=-.5) + 
  annotate("segment", x=full_info, xend=shrunk, y=250, yend=250, 
           size=.2, 
           arrow=arrow(length=unit(.07, "inches"), ends="both", type="open")
           ) + 
  annotate("text", x= (shrunk + saa)/2, y=225, label="12.7%", 
           family="Times New Roman", size=3, vjust=-.5) + 
  annotate("segment", x=full_info, xend=saa, y=225, yend=225, 
           size=.2, 
           arrow=arrow(length=unit(.07, "inches"), ends="both", type="open")
  )
  
g<- 
  g + annotate("text", label="Full-Info Optimum", 
             x=full_info, y=175, angle=90, 
             family="Times New Roman", size=3, vjust=-.6, hjust="outward"
             )

g 

ggsave("../../DataPoolingTex/Paper_V1/Figures/IllustratingDataPooling.pdf", 
       g, height=5/7 * 4, width=4, units="in")





