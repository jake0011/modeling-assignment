## Assumptions for the drift mechanism and stochastic model.
From the options: thermal, aging, calibration decay, we should choose to model aging / calibration-decay as the primary drift mechanism. More specifically:
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
