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
| Sampling interval                    | $( T )$                | 1 (unit time)                  | Use a normalized time step (e.g. 1 second, or whatever time unit) |
| Drift increment standard deviation   | $( \sigma_d )$         | 0.0005                         | Small increment so drift builds gradually                         |
| Initial drift                        | $( d_0 )$              | 0                              | Start from zero bias                                              |
| (Optional) Seed for random generator | —                    | a fixed integer (e.g. 0, 1234) | To make results reproducible                                      |



---
Yes — that’s a good idea: we can separate the **parameter sets** into two groups:

1. **Drift component only** (i.e. parameters relevant just for modeling drift)
2. **Full system** (which includes drift + measurement noise + true signal)

Below is a recommended split, with values and justification, for each. You can use these when building your Simulink model or MATLAB code.

---

## 1. Parameter Set for the **Drift Component Only**

When focusing strictly on the drift model $(i.e. ( d_{k+1} = d_k + w_k ))$, these are the relevant parameters:


| Parameter                            | Symbol               | Value                          | Description / Reasoning                                           |
| ------------------------------------ | -------------------- | ------------------------------ | ----------------------------------------------------------------- |
| Number of time steps                 | $(N_{\text{drift}})$ | 2000                           | Enough steps to observe drift accumulation                        |
| Sampling interval                    | (T)                | 1 (unit time)                  | Use a normalized time step (e.g. 1 second, or whatever time unit) |
| Drift increment standard deviation   | $(\sigma_d)$         | 0.0005                         | Small increment so drift builds gradually                         |
| Initial drift                        | $(d_0)$              | 0                              | Start from zero bias                                              |
| (Optional) Seed for random generator | —                    | a fixed integer (e.g. 0, 1234) | To make results reproducible                                      |

So when we simulate **drift only**, we implement:

$d_{k+1} = d_k + w_k,\quad w_k \sim \mathcal{N}(0, \sigma_d^2)$

with $( d_0 = 0 )$, $( \sigma_d = 0.0005 )$, over 2000 steps, with step interval ( T = 1 ).


[1]: https://www.mdpi.com/1424-8220/22/14/5225?utm_source=chatgpt.com "Research on Random Drift Model Identification and Error Compensation Method of MEMS Sensor Based on EEMD-GRNN"
[2]: https://daischsensor.com/understanding-how-random-walk-in-imu-sensors/?utm_source=chatgpt.com "Understanding How Random Walk in IMU sensors | IMU Noise"
[3]: https://arxiv.org/abs/2202.09360?utm_source=chatgpt.com "Analytic Method for Estimating Aircraft Fix Displacement from Gyroscope's Allan-Deviation Parameters"

