data {
  // Number of depths
  int<lower = 0> n_depths;
  
  // Number of time points
  int<lower = 0> n_times;
  
  // Vector of depths measurements were taken at
  vector[n_depths] depths;
  
  // Matrix of measurements, each row is a set of measurements at one time point
  // These measurements must be on the ORIGINAL scale in order for the priors 
  // to make any kind of physical sense.
  matrix[n_times, n_depths] densities;
}

parameters {  
  // regression parameters with appropriate constraints
  vector[n_times] beta_zero_raw;
  vector<lower = 0>[n_times] beta_one_raw;
  vector<lower = 0>[n_times] beta_three_raw;
  vector<lower = 0>[n_times] beta_six_raw;

  vector[2] beta_midpoint_raw[n_times];

  // regression coefficient means
  // because we can't do fancy constraints, have to enumerate them all out.
  real mean_beta_zero_raw;
  real mean_beta_one_raw;
  real mean_beta_three_raw;
  real mean_beta_six_raw;
  real mean_beta_midpoint_raw [2];

  // variances of the regression coefficients
  vector<lower=0>[6] sigma_beta;
  
  // variance of the regression curve
  real<lower = 0> sigma_curve;
  
}

transformed parameters {
  matrix[n_times, n_depths] fitted_values;
  real mean_beta_zero = 1025 + 10 * mean_beta_zero_raw;
  real<lower = 0> mean_beta_one = 5 + 2 * mean_beta_one_raw;
  real<lower = 0> mean_beta_three = 80 + 15 * mean_beta_three_raw;
  real<lower = 0> mean_beta_six = 80 + mean_beta_six_raw;
  positive_ordered[2] mean_beta_midpoint;
  
  vector[n_times] beta_zero = mean_beta_zero + sigma_beta[1] * beta_zero_raw;
  vector<lower = 0>[n_times] beta_one = mean_beta_one + sigma_beta[2] * beta_one_raw;
  vector<lower = 0>[n_times] beta_three = mean_beta_three + sigma_beta[4] * beta_three_raw;
  vector<lower = 0>[n_times] beta_six = mean_beta_six + sigma_beta[6] * beta_six_raw;

  // we need the ordered constraint otherwise there is an identifiability 
  // issue.
  positive_ordered[2] beta_midpoint[n_times];  

  mean_beta_midpoint[1] = 75 + 15 * mean_beta_midpoint_raw[1];
  mean_beta_midpoint[2] = 150 + 15 * mean_beta_midpoint_raw[2];

  for (tt in 1:n_times) {
    beta_midpoint[tt, 1] = mean_beta_midpoint[1] + sigma_beta[3] * beta_midpoint_raw[tt, 1];
    beta_midpoint[tt, 2] = mean_beta_midpoint[2] + sigma_beta[5] * beta_midpoint_raw[tt, 2];

    // vectorwise over individuals.
    fitted_values[tt,] = (beta_zero[tt] - beta_one[tt] * tanh((depths + beta_midpoint[tt, 1]) / beta_three[tt]) +
                                       - beta_one[tt] * tanh((depths + beta_midpoint[tt, 2]) / beta_six[tt]))'; 
  }
  
}

model {
  for (tt in 1:n_times) {
    // vectorwise over individuals.
    densities[tt,] ~ normal(fitted_values[tt,], sigma_curve);
  
    beta_midpoint_raw[tt, 1] ~ normal(0, 1);
    beta_midpoint_raw[tt, 2] ~ normal(0, 1);
  }
  
  // "elicited" priors -
  // this prior would make no sense? I want to test it, might break things.
  beta_zero_raw ~ normal(0, 1);
  beta_one_raw ~ normal(0, 1);
  beta_three_raw ~ normal(0, 1);
  beta_six_raw ~ normal(0, 1);
  
  mean_beta_zero_raw ~ normal(0, 1);
  mean_beta_one_raw ~ normal(0, 1);
  mean_beta_three_raw ~ normal(0, 1);
  mean_beta_six_raw ~ normal(0, 1);

  mean_beta_midpoint_raw[1] ~ normal(0, 1);
  mean_beta_midpoint_raw[2] ~ normal(0, 1);

  // no extra truncation here because it is of type vector, and Stan does not
  // yet support truncation on vector types
  sigma_beta ~ normal(0, 15);
  sigma_curve ~ normal(0, 0.25);
}
