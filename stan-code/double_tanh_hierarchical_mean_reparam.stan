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
  vector[n_times] beta_zero;
  
  vector<lower = 0>[n_times] beta_one;
  // vector<lower = 0>[n_times] beta_four;

  vector<lower = 0>[n_times] beta_three;
  vector<lower = 0>[n_times] beta_six;

  // 2018-03-21 I think accessing this object will look something like this:
  // beta_midpoint[n_times, 1] for beta_two
  // beta_midpoint[n_times, 2] for beta_five
  // we need the ordered constraint otherwise there is an identifiability 
  // issue.
  positive_ordered[2] beta_midpoint[n_times];
  
  

  // regression coefficient means
  
  // because we can't do fancy constraints, have to enumerate them all out.
  real mean_beta_zero;
  real<lower = 0> mean_beta_one;
  // real<lower = 0> mean_beta_four;
  real<lower = 0> mean_beta_three;
  real<lower = 0> mean_beta_six;
  positive_ordered[2] mean_beta_midpoint;

  // variances of the regression coefficients
  vector<lower=0>[6] sigma_beta;
  
  // variance of the regression curve
  real<lower = 0> sigma_curve;
  
}

transformed parameters {
  // matrix[n_times, 4] beta_final;
  matrix[n_times, n_depths] fitted_values;
  for (tt in 1:n_times) {
    // beta_final[tt,] = (beta_mean + beta_raw[tt,]' .* sigma_beta)';
    // vectorwise over individuals.
   fitted_values[tt,] = (beta_zero[tt] - beta_one[tt] * tanh((depths + beta_midpoint[tt, 1]) / beta_three[tt]) +
                                       - beta_one[tt] * tanh((depths + beta_midpoint[tt, 2]) / beta_six[tt]))'; 
  }
  
}

model {
  for (tt in 1:n_times) {
    // vectorwise over individuals.
    densities[tt,] ~ normal(fitted_values[tt,], sigma_curve);
    // beta_raw[tt, ] ~ normal(0, 1);

    beta_midpoint[tt, 1] ~ normal(mean_beta_midpoint[1], sigma_beta[3]);
    beta_midpoint[tt, 2] ~ normal(mean_beta_midpoint[2], sigma_beta[5]);
  }
  
  // "elicited" priors

  // this prior would make no sense? I want to test it, might break things.
  beta_zero ~ normal(mean_beta_zero, sigma_beta[1]);

  beta_one ~ normal(mean_beta_one, sigma_beta[2]);
  beta_three ~ normal(mean_beta_three, sigma_beta[4]);

  //beta_four ~ normal(mean_beta_four, sigma_beta[5]);
  beta_six ~ normal(mean_beta_six, sigma_beta[6]);
  
  mean_beta_zero ~ normal(1025, 10);
  mean_beta_one ~ normal(5, 2) T[0,];
  mean_beta_three ~ normal(80, 15) T[0,];

  //mean_beta_four ~ normal(3, 5) T[0,];
  mean_beta_six ~ normal(80, 15) T[0,];


  mean_beta_midpoint[1] ~ normal(75, 15);
  mean_beta_midpoint[2] ~ normal(150, 15);

  // no extra truncation here because it is of type vector, and Stan does not
  // yet support truncation on vector types
  sigma_beta ~ normal(0, 15);
  sigma_curve ~ normal(0, 0.25) T[0,];
}
