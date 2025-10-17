## Justifications for Assumptions and Modeling Decisions (with citations)

Below are the major assumptions and decisions we made in the modeling so far, each with a justification and relevant reference(s).

---

### 1. Choosing aging / calibration drift mechanism

**Assumption / decision:**  
The primary drift mechanism is a slowly varying bias (aging / calibration decay), and thermal or faster perturbations are not explicitly modeled.

**Justification:**

- Aging / calibration drift is often a dominant long-term bias in sensors and is more amenable to stochastic modeling than rapid thermal effects.
- By focusing on calibration drift only, we avoid needing extra environmental inputs (e.g., temperature), which would complicate the model unnecessarily for a first implementation.
- Many works in sensor drift modeling assume slow bias evolution as a first step before more complex modeling. This approach is standard in the literature of drift compensation and inertial sensor modeling.

---

### 2. Modeling drift as a **random walk**

**Assumption / decision:**  
$d_{k+1} = d_k + w_k,\quad w_k \sim \mathcal{N}(0,\sigma_d^2)$

**Justification:**

- The random walk (i.e., ARIMA(0,1,0) model) is a canonical model for nonstationary processes with drift; it captures cumulative bias accumulation without reversion or memory. In ARIMA theory, a simple random walk is often the baseline nonstationary model[1](https://people.duke.edu/~rnau/notes_on_the_random_walk_model--robert_nau.pdf).
- Random walk models have been used to represent drift in time series contexts and are a special case of ARIMA models[1](https://people.duke.edu/~rnau/notes_on_the_random_walk_model--robert_nau.pdf).
- The random walk’s property of unbounded variance growth matches the expectation that drift uncertainty increases over time in absence of correction.

---

### 3. Linear state-space augmentation (signal + drift) and use of a **linear Kalman filter**

**Assumption / decision:**  
We represent the state as  
$\mathbf{s}_k = \begin{pmatrix} x_k \\ d_k \end{pmatrix}$  
with  
$\mathbf{s}_{k+1} = F \mathbf{s}_k + w_k,\quad y_k = H \mathbf{s}_k + v_k$  
and employ a **standard (linear) Kalman filter**.

**Justification:**

- Because the state evolution and measurement relationship are **linear**, the standard Kalman filter is optimal (in the mean-squared error sense) when the noises are Gaussian[2](https://en.wikipedia.org/wiki/Kalman_filter).
- The augmented state formulation allows joint estimation of drift and the true signal in a unified framework, simplifying compensation.
- Avoiding nonlinear methods (EKF, UKF) is justified because our model is inherently linear, so simpler is better (and more stable).

---

### 4. Noise statistics: $Q$, $R$, and $N = 0$

**Assumption / decision:**

- $Q = \mathrm{diag}(\sigma_x^2, \sigma_d^2)$, with $\sigma_x = 0$  
- $R = \sigma_v^2$  
- Cross-covariance $N = 0$

**Justification:**

- We simulate process noise in drift increments with variance $\sigma_d^2$, so matching that in $Q$ leads to consistency between model and simulation.
- The true signal is held constant in simulation (i.e., no dynamics beyond bias), so $\sigma_x = 0$ is a simplifying assumption.
- In Kalman filter theory, it is standard to assume process and measurement noise are uncorrelated (i.e., $N = 0$) unless cross-correlation is known[2](https://en.wikipedia.org/wiki/Kalman_filter).
- Linear Kalman filtering derivation typically assumes zero-mean, uncorrelated Gaussian noise processes[3](https://web.mit.edu/kirtley/kirtley/binlustuff/literature/control/Kalman%20filter.pdf).

---

### 5. Initial conditions: $\hat{\mathbf{s}}_0 = [0;\;0]$, $P_0 = I$

**Assumption / decision:**  
The filter begins with zero state estimates and moderate uncertainty covariance.

**Justification:**

- In simulation, the true initial drift and signal are zero, so starting with zero state estimate is reasonable.
- Using a diagonal identity covariance for $P_0$ gives the filter “room” to learn the relative uncertainties from measurement corrections.
- Typically, the initial covariance choice is not critical if the filter converges rapidly; after some time, the effect of initial conditions diminishes.

---

### 6. Before vs After error metrics (RMSE, MAE, drift rate)

**Assumption / decision:**  
We compute errors before compensation (raw), after compensation (corrected), drift estimation error, and drift rates to evaluate performance.

**Justification:**

- Comparing raw measurement error vs post-compensation error quantifies the value of the drift removal approach.
- RMSE and MAE are standard error metrics in estimation and forecasting tasks. They provide complementary views (quadratic vs absolute).
- Drift rate (slope) comparison helps verify whether the estimated bias trend matches the true bias evolution over time.

These are standard evaluation practices in signal processing and estimation tasks.

---

