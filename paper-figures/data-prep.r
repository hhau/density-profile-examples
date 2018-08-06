# 1/08/2018 11:16:12 AM
# The data processing script, to go from both model fit RDS files, to the
# beta samples array used by the figure makers

library(ddcurves2)
library(hdf5r)
library(rstan)

model_fit_one <- readRDS("../Example/model-fit-one.rds")
model_fit_two <- readRDS("../Example/model-fit-two.rds")

pars <- grep("^beta_[a-z]+$", model_fit_one@model_pars, value = TRUE)

first_half_beta_samples <- extract(model_fit_one, pars)
first_half_output_list <- list(
  beta_zero = first_half_beta_samples$beta_zero,
  beta_one = first_half_beta_samples$beta_one,
  beta_two = first_half_beta_samples$beta_midpoint[, , 1],
  beta_three = first_half_beta_samples$beta_three,
  beta_five = first_half_beta_samples$beta_midpoint[, , 2],
  beta_six = first_half_beta_samples$beta_six
)

second_half_beta_samples <- extract(model_fit_two, pars)
second_half_output_list <- list(
  beta_zero = second_half_beta_samples$beta_zero,
  beta_one = second_half_beta_samples$beta_one,
  beta_two = second_half_beta_samples$beta_midpoint[, , 1],
  beta_three = second_half_beta_samples$beta_three,
  beta_five = second_half_beta_samples$beta_midpoint[, , 2],
  beta_six = second_half_beta_samples$beta_six
)

output_list <- list()
n_samples <- 1500

for (beta_name in names(first_half_output_list)) {
  output_list[[beta_name]] <- cbind(
    first_half_output_list[[beta_name]][1:n_samples, ],
    second_half_output_list[[beta_name]][1:n_samples, ]
  )
}

index_vec <- as.numeric(rownames(a0_data_no_zeros))
for (ii in 1:length(output_list)) {
  output_list[[ii]] <- output_list[[ii]][, index_vec]
}

output_array <- array(
  as.numeric(unlist(output_list)),
  dim = c(nrow(output_list$beta_zero),
          ncol(output_list$beta_zero),
          length(output_list))
)

# check
all(output_array[, , 1] == output_list$beta_zero)

output_file <- paste0("./", "beta-samples-array-all-data.h5")
file.h5 <- H5File$new(output_file, mode = "w")
file.h5$create_group("data")
file.h5[["data/beta_samples"]] <- output_array
file.h5$close_all()

