library(R.matlab)
library(ggplot2)
library(gridExtra)
df <- data.frame(matrix(unlist(readMat('/Users/RomanKoshkin/Downloads/output_grid (6).mat')),
                        ncol=6, byrow=T))
names(df)[1:6] <- c('a_suc', 'u_suc', 'lambda', 'en', 'filt','len_win_clas')

a <- ggplot(data=df, aes(en,lambda)) +
  geom_tile(aes(fill = a_suc)) +
  scale_x_continuous(expand = c(0,0), breaks = unique(df$en)) +
  scale_y_continuous(expand = c(0,0), breaks = unique(df$lambda)) +
  ggtitle('Accuracy of Attended Decoders')

b <- ggplot(data=df, aes(en,lambda)) +
  geom_tile(aes(fill = u_suc)) +
  scale_x_continuous(expand = c(0,0), breaks = unique(df$en)) +
  scale_y_continuous(expand = c(0,0), breaks = unique(df$lambda)) +
  ggtitle('Accuracy of Unattended Decoders')

grid.arrange(a,b,nrow=1)

