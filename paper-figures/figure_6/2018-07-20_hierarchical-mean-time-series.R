library(hdf5r)
library(ggplot2)
library(ddcurves2)

beta_samples_file <- h5file("../beta-samples-array-all-data.h5")
# names(beta_samples_file[["data/beta_samples"]])
beta_samples <- beta_samples_file[["data/beta_samples"]][,,] 

# lubridate::as_datetime(a0_data_no_zeros$datetime)

plot_df <- dplyr::bind_rows(pbapply::pblapply(1:6, function(x) {
  sub_array <- beta_samples[, , x]
  
  res <- data.frame(
    x = 1:dim(beta_samples)[2],
    y_mean = apply(sub_array, 2, mean),
    y_lower = apply(sub_array, 2, quantile, 0.025),
    y_upper = apply(sub_array, 2, quantile, 1 - 0.025),
    datetime = lubridate::as_datetime(a0_data_no_zeros$datetime),
    data_set = c(rep(1, 727), rep(2, dim(beta_samples)[2] - 727))
  )
}))

y_labs <- c(
  expression(atop(beta[0], ~(kg/m^{3}))), 
  expression(atop(beta[1], ~(kg/m^{3}))),
  expression(atop(beta[2], ~(m))),
  expression(atop(beta[3], ~(m))),
  expression(atop(beta[4], ~(m))),
  expression(atop(beta[5], ~(m)))
)

plot_df <- cbind(plot_df,
                 beta_factor = factor(rep(0:5, each = dim(beta_samples)[2]),
                                      labels = as.character(y_labs)))
plot_df$data_set <- as.factor(plot_df$data_set)


# full_beta_plot <- ggplot(data = plot_df) +
#   geom_line(aes(x = x, y = y_mean)) +
#   geom_ribbon(aes(x = x, ymin = y_lower, ymax = y_upper), alpha = 0.2) +
#   facet_grid(beta_factor~., scales = "free_y", labeller = label_parsed) +
#   theme_bw() +
#   theme(strip.text.y = element_text(angle = 0)) +
#   xlab("Time Index") +
#   ylab("Coefficient value") +
#   scale_x_continuous(expand = c(0.025,0.025))
# full_beta_plot  
# 
# ggsave(filename = dated_filename("big-mean-timeseries.pdf"), width = 8 * 0.8, height =  12 * 0.8)

full_beta_plot <- ggplot(data = plot_df) +
  geom_line(aes(x = datetime, y = y_mean, group = data_set)) +
  geom_ribbon(aes(x = datetime, ymin = y_lower, ymax = y_upper, group = data_set), alpha = 0.2) +
  facet_grid(beta_factor~., scales = "free_y", labeller = label_parsed) +
  theme_bw() +
  theme(strip.text.y = element_text(angle = 0)) +
  xlab("Date") +
  ylab("Coefficient value") +
  scale_x_datetime(expand = c(0.025,0.025))
full_beta_plot  

ggsave(filename = dated_filename("big-mean-timeseries.pdf"), width = 9 * 0.8, height =  10 * 0.8)
