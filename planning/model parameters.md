## Drift Mechanism Choice: 
From the options: thermal, aging, calibration-decay, we should choose to model aging / calibration-decay as the primary drift mechanism. More specifically:
 - We assume a slowly increasing bias over time due to aging of the sensor’s components (e.g. electronics, sensor elements) or gradual degradation of calibration (i.e. calibration coefficients slowly drifting).
 - We will also assume that thermal fluctuations are not large enough (or are well compensated elsewhere) so that thermal drift is not explicitly modeled. Essentially, we treat temperature as fixed or negligible with respect to drift mechanisms.

So the drift mechanism is aging + calibration-decay, modeled as a bias that slowly changes over time in a stochastic way.

---

## What assumptions are being made about drift under this choice

Here are the assumptions we will use, given we focus on aging/calibration drift:

1. **Drift is additive**: the drift adds a bias to the sensor reading, i.e. output = true value + drift + measurement noise.

2. **Drift evolves slowly over time**, without abrupt jumps. I assume no sudden failure, damage, or step changes—just gradual change.

3. **Drift increment statistics**: I’ll assume the increments in drift (how much drift increases from one time step to the next) behave like independent (or weakly correlated) Gaussian noise of small variance.

4. **Neglect other drift mechanisms**: thermal drift, environmental interference, mechanical damage etc. are not modeled explicitly. Their effect is assumed to be either negligible, constant, or absorbed into the stochastic drift noise.

5. **Stationarity of drift‐increment distribution**: the variance of the drift increments is constant over time (i.e., the aging rate doesn’t change over the course of the experiment).

6. **Observability**: we assume that the drift can be distinguished from measurement noise if we have enough data, because drift is slow and measurement noise is zero‐mean with known (or estimable) variance.


---
## Stochastic Model Choice: Random walk

### Justification:

1. **Simplicity + tractability**

   * A random walk is one of the simplest stochastic processes: drift in each time step is just the previous drift plus a small random increment.
   * It is easy to simulate, analyze, and integrate into state-space models (e.g. Kalman filter) because it's linear and Gaussian (if increments are Gaussian).
   * Many sensor drift studies use a random walk or random walk‐like model as a baseline, before trying more complex models. For example, methods for drift in MEMS sensors often treat the drift/error accumulation via simple random walk processes when no better structural model is identifiable. ([MDPI][1])

2. **Matches observed behavior for many sensors under aging/calibration drift**

   * For many sensors that degrade over time, the bias (error) accumulates gradually without a strong corrective tendency; i.e. there is no strong restoring force bringing the drift back. That is characteristic of a random walk (or a process with drift, but where increments persist).
   * Literature in IMU drift (gyroscopes, accelerometers) describes "bias drift" whose model includes random walk components. For example, integration of white noise or bias instability leads to drift that grows with time due to random walk behavior. ([daischsensor.com][2])

3. **Non-stationarity reflecting real drift**

   * Random walk is non-stationary: variance of drift increases over time. That matches what is observed in many real sensors: you see increased drift spread the longer the device has been operating, unless recalibration intervenes.
   * For example, in documentations of random walk models, variance is proportional to time (or grows with time) in the drift component. 

4. **Baseline / fallback when more detailed modeling is not justified**

   * If you don’t have good data about temperature dependence, aging rate, or calibration decay dynamics, assuming a random walk is a reasonable baseline. It captures randomness and gradual accumulation of bias, with minimal prior information required.

   * In methods for modeling sensor drift where more structured models aren’t available or conditions are not well understood, people often “use a random walk model instead” of designing a more complex transition model. 

5. **Integration and compatibility with estimation frameworks**

   * The random walk model aligns nicely with Kalman filtering (state‐space) and enables easy computation of predictions, covariances, etc. Because random walk has simple linear form, i.e.:

     $$
     d_{k+1} = d_k + w_k
     $$

     this leads to a simple state transition matrix and noise term. That makes it computationally efficient and easy to implement.

   * Also, Allan variance analyses (used in inertial sensor characterization) often identify random walk components in sensor error spectra, which suggests that random walk is empirically relevant. ([daischsensor.com][2])


### Summary:
* We focus on **aging / calibration drift** mechanism, which tends to accumulate bias gradually over time, rather than rapidly or with strong negative feedback.

* We assume limited external information (no detailed thermal model, no strong environmental forcing), so a minimal stochastic model is appropriate.

* Random walk gives a simple, interpretable model, easy to simulate, estimate, and evaluate.

* It sets a baseline model: once you have that working, you can compare its performance to more complex models (AR(1), Gaussian process, etc.)

* For many sensor drift circumstances (especially early in use), the behavior of bias seems consistent with random walk (slow drift, increasing variance, no immediate corrections).

---
## Parameters for modelling drift component only: 

| Parameter                            | Symbol               | Value                          | Description / Reasoning                                           |
| ------------------------------------ | -------------------- | ------------------------------ | ----------------------------------------------------------------- |
| Number of time steps                 | $( N_{\text{drift}} )$ | 2000                           | Enough steps to observe drift accumulation                        |
| Sampling interval                    | $( T )$                | 1 (unit time)                  |  A normalized time step (e.g. 1 second, 1 minute or 1 day or whatever time unit) |
| Drift increment standard deviation   | $( \sigma_d )$         | 0.0005                         | Small increment so drift builds gradually                         |
| Initial drift                        | $( d_0 )$              | 0                              | Start from zero bias                                              |

                     

So when we simulate **drift only**, we implement:

$d_{k+1} = d_k + w_k,\quad w_k \sim \mathcal{N}(0, \sigma_d^2)$

with $( d_0 = 0 )$, $( \sigma_d = 0.0005 )$, over 2000 steps, with step interval ( T = 1 ).

---
### Simulink Model of the drift only component:

<img width="902" height="459" alt="image" src="https://github.com/user-attachments/assets/8a2bad5c-9cce-4b09-b71e-cdef7a84bf89" />

---
### 2. Simulation and drift compensation implementation using Kalman filter 

- After formulating the stochastic drift model (random walk), we simulated synthetic sensor data combining **true signal + drift + measurement noise**.  
- We then implemented a **standard linear Kalman filter** to estimate drift ($\hat{d}_k$) and true signal ($\hat{x}_k$), and thereby compensate the drift by subtracting $\hat{d}_k$ from the measurements.  
- The simulation + estimation pipeline allows us to evaluate filter performance (error metrics, time series plots, residual analysis).

---
### Block Diagram:

<img width="1174" height="469" alt="image" src="https://github.com/user-attachments/assets/dfd6d02f-277d-4b5a-baee-cdf79bb9bf51" />

---

### Simulation Setup

- **Time horizon**: $N = 2000$ samples  
- **Sampling interval**: $T = 1$ (normalized time unit)  
- **Drift process**:  
  $d_{k+1} = d_k + w_k,\quad w_k \sim \mathcal{N}(0, \sigma_d^2),\quad \sigma_d = 0.0005$  
  initialized $d_0 = 0$  
- **Measurement generation**:  
  $y_k = x_k + d_k + v_k,\quad v_k \sim \mathcal{N}(0, \sigma_v^2),\quad \sigma_v = 0.01$  
  where the true signal $x_k$ was chosen as constant zero (for simplicity)  
- **Random seed** fixed for reproducibility  

This setup ensures that drift accumulates slowly while measurement noise dominates short-term variations, making the filter’s task nontrivial but feasible.

---


---

### Implementation in MATLAB  

- The simulation and filter were implemented in a single MATLAB script.  
- Arrays were preallocated for performance (e.g. `d_true`, `y`, `s_hat`, `P_store`).  
- The loop iterates from sample 2 to $N$, performing prediction and update.  
- After filtering, we extracted $\hat{d}_k$ (from `s_hat(2,k)`) and $\hat{x}_k$ (from `s_hat(1,k)`).  
- We plotted:
  - True drift vs estimated drift  
  - Measured signal vs corrected signal (i.e. $y_k - \hat{d}_k$)  
  - Estimated true signal vs actual (zero baseline)  
- We also computed **RMSE** and **MAE** for drift estimation error and signal estimation error.

---

### Key Observations & Practical Points

- **Negative or positive drift**: Because increments $w_k$ are zero-mean, the drift trajectory may wander negative or positive—this is natural and expected.  
- **Residual & innovation**: Checking the statistics (mean, whiteness) of the innovation $\nu_k$ can validate whether the filter assumptions hold (i.e. residual should be approximately zero-mean and white).  
- **Tuning $Q$ and $R$**: The performance (how fast the filter tracks drift vs noise) depends critically on correct choice of $Q$ and $R$. Overstating $Q$ causes the filter to follow noise; understating $Q$ causes lag in tracking drift.  
- **Covariance evolution**: The error covariance $P$ generally converges or stabilizes over time if noise assumptions are consistent.  
- **Limitations**: In real sensors, drift may not follow pure random walk, noise may not be Gaussian, or drift increments may vary over time. In those cases, EKF/UKF or adaptive filtering may outperform the simple Kalman filter.

---

### Suggestions for Report Integration

- Include a **block diagram** showing data flow: drift generator → measurement → Kalman filter → estimated drift & corrected signal.  
- In the report, convert these notes into structured subsections (Simulation Setup, Filter Design, Implementation, Results & Metrics, Discussion).  
- Present key plots (true vs estimate, error curves) along with error tables.  
- Include discussion of tuning decisions (why put $\sigma_d = 0.0005$, $\sigma_v = 0.01$, initial $P$) and sensitivity tests.  
- Discuss potential mismatches (model vs reality) and how you might extend to EKF/UKF or adaptive filtering.

---

[1]: https://www.mdpi.com/1424-8220/22/14/5225?utm_source=chatgpt.com "Research on Random Drift Model Identification and Error Compensation Method of MEMS Sensor Based on EEMD-GRNN"
[2]: https://daischsensor.com/understanding-how-random-walk-in-imu-sensors/?utm_source=chatgpt.com "Understanding How Random Walk in IMU sensors | IMU Noise"
[3]: https://arxiv.org/abs/2202.09360?utm_source=chatgpt.com "Analytic Method for Estimating Aircraft Fix Displacement from Gyroscope's Allan-Deviation Parameters"

