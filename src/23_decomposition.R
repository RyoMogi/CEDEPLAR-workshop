source("src/12_myfunction.R")

# colour palette ---------------------------------------------------------------

mypalette  <- rev(brewer.pal(8, "YlGnBu"))
mypalette2 <- rev(brewer.pal(8, "YlOrRd"))
decomp_palette <- c(mypalette[1:4], "white", "white", mypalette2[c(6, 4, 2, 1)])

levels <- c(-1, -0.1, -0.01, -0.001, -0.0001, 0, .0001, .001, .01, .1, 1)

customAxis <- function() { 
  n <- length(levels) 
  y <- seq(min(levels), max(levels), length.out = n) 
  rect(0, y[1:(n-1)], 1, y[2:n], col = decomp_palette) 
  axis(4, at = y, labels = levels) 
}

# calculate px -----------------------------------------------------------------

Names <- c("USA", "SWE")
Names2 <- c("The US", "Sweden")

px1 <- lxpx(data_c = USA_c, data_p = USA_p, lxpx = "px")
px2 <- lxpx(data_c = SWE_c, data_p = SWE_p, lxpx = "px")

## The correct assignment of contributions and the cumulative changes
CALlxDecompBC <- CALCDecompFunction(px1, px2, "Lx", Names[1], Names[2])

CALlxD  <- matrix(NA, 38, 38)
CALlxDS <- CALlxD

Age <- c(12:49)

BC <- 1966:2003

for (y in 1:38){
  for (x in 1:y){
    CALlxD[x, (38 - y + x)]  <- CALlxDecompBC[x, y]			
    CALlxDS[x, (38 - y + x)] <- sum(CALlxDecompBC[(1:x), y])
  }
}

# +12 = the period of CALC
colnames(px1)[ncol(px1)]

tab_contr <- CALlxDecompBC
# table: contribution of each age and cohort
for(i in 1:ncol(CALlxDecompBC)){
  tab_contr[, 1 + ncol(CALlxDecompBC) - i] <- round(CALlxDecompBC[, i], 4)
}
colnames(tab_contr) <- BC
rownames(tab_contr) <- Age

# plot -------------------------------------------------------------------------
# cumulative
options(scipen = 10)
Nm <- paste("out/Fig", Names[2], "-", Names[1], "_bc.pdf", sep = "")
pdf(Nm)
par(cex.axis = 1)
par(oma = c(1, 0, 0, 0)) #bottom, right, top, left
filled.contour(BC, Age, t(CALlxDS), levels = levels, 
               col = decomp_palette, key.axes = customAxis(), 
               ylab = "", xlab = "", cex.lab = 1.1,
               plot.axes = {axis(1, at = c(1966, seq(1970, 2000, by = 5), 2003), 
                                 labels = c("", "1970\n(1982)", "1975\n(1987)", "1980\n(1992)", 
                                            "1985\n(1997)", "1990\n(2002)", "1995\n(2007)", 
                                            "2000\n(2012)", "2003\n(2015)"), hadj = 0.6, padj = 0.5, cex.axis = 0.9)
                 axis(2, at = seq(15, 50, by = 5), labels = seq(15, 50, by = 5))})
title(ylab = "Cumulative Age and Cohort Contribution", font.lab = 2)
mtext("Birth Cohort\n(Year)", 1, line = 4.5, adj = 0.4, font = 2) # adj: (-)left-right(+), line: (+)down-up(-)
mtext(Names2[2], 3, 0.5, adj = 0.9, cex = 0.9)
mtext(Names2[1], 1, 0.5, adj = 0.9, cex = 0.9)
dev.off()
