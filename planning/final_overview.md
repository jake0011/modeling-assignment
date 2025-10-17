# Project Overview:

## 1. Problem Setup & Drift Modeling

- We clarified **which sensor drift mechanism** we are modeling: an **aging / calibration-decay bias** that slowly accumulates over time.  
- We justified why a **random walk (biased increments)** is a suitable stochastic model for this drift: simple, tractable, matches typical slow bias accumulation behaviors.  
- We formulated the stochastic drift model:  
  $d_{k+1} = d_k + w_k,\; w_k \sim \mathcal{N}(0, \sigma_d^2)$  
  so drift is additive and evolves over time via Gaussian increments.

---

## 2. Simulation of Drift + Measurement

- We set up simulation parameters (number of steps $N$, drift increment standard deviation $\sigma_d$, measurement noise standard deviation $\sigma_v$, initial drift $d_0$, and true signal).  
- We generated the **true drift trajectory** `d_true` via random walk.  
- We simulated **measurements** $y_k = x_k + d_k + v_k$, with $x_k$ as a known (baseline) true signal (chosen zero) and $v_k$ as Gaussian measurement noise.  
- This simulated dataset gives us ground truth ($d_k$, $x_k$) and observations ($y_k$) to test our drift compensation algorithms.

---

## 3. Kalman Filter Design & Implementation

- We defined an **augmented state vector** combining the true signal and drift:  
  $\mathbf{s}_k = \begin{pmatrix} x_k \\ d_k \end{pmatrix}$

- We built the **state-space model**:

  - State transition:  
    $\mathbf{s}_{k+1} = F \,\mathbf{s}_k + w_k,\quad F = \begin{pmatrix}1 & 0 \\ 0 & 1\end{pmatrix}$

  - Measurement model:  
    $y_k = H\,\mathbf{s}_k + v_k,\quad H = [1\;\;1]$

  - Noise covariances: $Q$ (for process) and $R$ (for measurement), with cross-covariance $N = 0$

- We specified initial conditions for the state estimate $\hat{\mathbf{s}}_0$ and error covariance $P_0$.  
- We implemented the **Kalman filter recursion** (predict + update) in MATLAB, storing state estimates $\hat{d}_k$ and $\hat{x}_k$.

---

## 4. Error Metrics & Before/After Analysis

- We added computations for **error metrics**:

  - **Before compensation errors**: error of raw readings $y_k - x_k$  
  - **After compensation errors**: error of compensated signal $y_k - \hat{d}_k$ or equivalently $\hat{x}_k - x_k$  
  - **Drift estimation error**: $\hat{d}_k - d_k$  
  - Metrics computed: **RMSE** and **MAE** for each of the above quantities  
  - We also computed **drift rate** (slope of drift over time) both in true drift and in estimated drift via linear fit

- We printed the metrics in the console for direct numeric comparison (before vs after, drift estimation performance, drift rate match)

---

## 5. Visualization of Performance

- We extended the MATLAB script to produce helpful graphs:

  1. **True vs estimated drift** over time  
  2. **Drift estimation error** time series  
  3. **Raw measurement vs corrected measurement**  
  4. **Error before vs error after compensation**  
  5. **Histogram of drift estimation errors**  
  6. **Scatter plot** $\hat{d}$ vs true $d$ (with ideal line)

- These plots allow you to visually evaluate how well the compensation is working, where errors occur, and bias / spread of estimation.

---

### Next Steps

- Running parameter sweeps / sensitivity analyses  
- Possibly implementing ARIMA or alternative compensation methods  
- Comparing methods quantitatively  
- Writing up results, discussions, and conclusions
