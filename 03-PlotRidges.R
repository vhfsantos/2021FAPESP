require('ggplot2')
require('ggridges')

df = data.frame()
for(bc in seq(1,6)){
	LSH = paste0("Stats/barcode0",bc,"LengthOfSingleHits.txt")
	SingleHitSize = read.table(LSH)
    df = rbind(df, data.frame(SingleHitSize,paste0('barcode0',bc)))
}

colnames(df) = c('SingleHitSize', 'Barcode')
p = ggplot(df, aes(y = Barcode)) +
	geom_density_ridges(aes(x = SingleHitSize), alpha = .8, color = "black") +
	theme_minimal() + 
	theme(text = element_text(size=20),axis.title.y = element_blank())
	
svg('Stats/SingleHitSize.svg')
p
dev.off()
