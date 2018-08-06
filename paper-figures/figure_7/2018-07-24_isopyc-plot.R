library(hdf5r)
library(magrittr)
library(ddcurves2)
library(tidyverse)

beta_file <- hdf5r::h5file("../beta-samples-array-all-data.h5")
beta_samples <- beta_file[["data/beta_samples"]][, ,]
beta_dim <- dim(beta_samples)

density_values <- seq(from = 1021.5, to = 1026, by = 0.5)
n_vals <- length(density_values)

iso_density_array <- array(
  dim = c(beta_dim[1:2], length(density_values)),
  dimnames = list(
    iteration = 1:beta_dim[1],
    time_index = 1:beta_dim[2],
    density_value = density_values
  )
)

root_function <- function(depth, target_density, beta_sample) {
  res <- target_density - ddcurves2:::.double_tanh_function(depth, beta_sample)
}

pb <- txtProgressBar(min = 1, max = beta_dim[1], style = 3)

for (ii in 1:beta_dim[1]) {
  setTxtProgressBar(pb, ii)
  for (zz in 1:beta_dim[2]) {
    for (qq in 1:length(density_values)) {
      root_res <- tryCatch({uniroot(
          f = root_function,
          interval = c(-255, 0),
          target_density = density_values[qq],
          beta_sample = beta_samples[ii, zz, ]
        )}, 
          error = function(e) {NA}
      )
      
      if (!is.list(root_res)) {
        iso_density_array[ii, zz, qq] <- root_res
      } else {
        iso_density_array[ii, zz, qq] <- root_res$root
      }
      
      rm(root_res)
      
    }
  }
}

cred_ints <- function(x, margin, alpha) {
  res <- data.frame(
    mean = apply(x, margin, mean, na.rm = TRUE),
    lower = apply(x , margin, quantile, alpha, na.rm = TRUE),
    upper = apply(x, margin, quantile, 1 - alpha, na.rm = TRUE)
  )
  return(res)
}


plot_df <- dplyr::bind_rows(pbapply::pblapply(seq_len(dim(iso_density_array)[2]), function(x) {
  
  # get the time point we are interested in
  sub_array <- iso_density_array[, x, ]
  
  # compute the mean and credible intervals for the isobars of interest
  temp_df <- cred_ints(sub_array, 2, 0.025)
    # some reshaping needs to occur here
  
  temp_df <- cbind(isopyc = rownames(temp_df) %>% as.numeric(), temp_df)

  # make the base of the data frame, with the time and the time index in
  # res <- data.frame(
  #   time_index = x,
  #   datetime = a0_data_no_zeros$datetime[x] %>% as.POSIXct
  # )
  # 
  # bind the resulting data.frames together.
  res <- cbind(
    time_index = x,
    datetime = a0_data_no_zeros$datetime[x] %>% as.POSIXct,
    temp_df
  )
  rownames(res) <- NULL
  return(res)
  
}))

data_set <- c(rep(1, 727 * n_vals), rep(2, (dim(iso_density_array)[2] - 727) * n_vals))
plot_df$data_set <- as.factor(data_set)
plot_df$isopyc <- as.factor(plot_df$isopyc)
saveRDS(plot_df, file = dated_filename("isopyc-plot-data-full.rds", folder_path = "./results/"))

# plot_df <- readRDS("../../results/2018-07-25_isopyc-plot-data-full.rds")

ggplot(data = plot_df, aes(datetime, group = interaction(isopyc, data_set))) + 
  geom_line(aes(y = mean, col = isopyc)) + 
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15) +
  theme_bw() +
  xlab("Date") +
  ylab("Depth (m)") + 
  scale_color_viridis_d(name = "Isopycnal", option = "B") +
  scale_y_continuous(limits = c(-255, 0.1)) + 
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = -255) +
  geom_vline(xintercept = as.POSIXct("2016-05-07"), lty = "dashed") + 
  geom_vline(xintercept = as.POSIXct("2016-08-26"), lty = "dashed") +
  geom_vline(xintercept = as.POSIXct("2016-10-09"), lty = "dashed")  

ggsave(filename = dated_filename("isopyc-full-with-datelines.pdf", folder_path = "./"), height = 7, width = 12)
