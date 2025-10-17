Below is a **draft of a “Results & Discussion”** section (written in report style) based on the work you’ve done so far, followed by **commentary notes** for defence for each section. You’ll want to adapt numbers / plots to your actual outputs, but this gives structure and sample insights.

---

## Results & Discussion

In this section we present the outcomes of our drift compensation experiments (using random-walk drift + measurement noise + Kalman filter), comparing before vs after compensation, analysing drift estimation, and interpreting strengths and limitations.

---

### Simulation Outputs

* The true drift ( d_k ) generated via random walk with standard deviation ( \sigma_d = 0.0005 ) exhibits slow accumulation over time. Early in the simulation, the drift remains small compared to measurement noise; toward the end, drift becomes more noticeable.
* The noisy measurement ( y_k = x_k + d_k + v_k ) (where ( x_k = 0 )) shows large fluctuations (noise) overlaid on slow drift, as expected.

---

### Compensation via Kalman Filter

* The estimated drift ( \hat d_k ) closely follows the true drift curve, especially after a “warm-up” period. There is an initial lag (or estimation delay) in the early time steps, but the drift estimate converges to truth as more data accrues.

* The corrected signal (i.e. ( y_k - \hat d_k )) shows much less bias over time; its mean error is closer to zero, and fluctuations are dominated by noise rather than drift after compensation.

---

### Error Metric Comparisons

| Metric                                            | Before Compensation     | After Compensation |
| ------------------------------------------------- | ----------------------- | ------------------ |
| RMSE (signal vs true)                             | [fill with your number] | [fill]             |
| MAE (signal vs true)                              | [fill]                  | [fill]             |
| Drift estimation RMSE ( ( \hat d_k ) vs ( d_k ) ) | —                       | [fill]             |
| Drift rate (true drift slope)                     | [fill]                  | [fill]             |
| Drift rate (estimated slope)                      | —                       | [fill]             |

* **RMSE / MAE** both reduce significantly after applying the Kalman filter, showing that compensation is effective.

* The error reduction is larger for RMSE than for MAE, suggesting that large deviations (outliers) are more strongly corrected, though some residual noise remains.

* The **drift rate** (slope of drift vs time) of the estimated drift closely matches the true drift rate. Any deviation tends to be small (e.g. estimated slope within ~[some percent] of the true).

---

### Visualization Insights

* The plot of ( d_k ) vs ( \hat d_k ) shows initial transient error (first few hundred samples) but then almost parallel growth, indicating good model match.
* The error time series (drift estimation error) tends to fluctuate around zero with no large bias over long time, although occasionally there are small systematic offsets.
* Histograms of drift error show approximately symmetrical error distribution (positive and negative errors), suggesting zero-mean error assumption is reasonable.

---

### Strengths & Limitations

**Strengths:**

* The model is simple, yet the Kalman filter is able to compensate drift well under these simulated conditions.
* The error metrics and plots show clear improvement before vs after, which validates the approach.
* The parameter choices (( \sigma_d, \sigma_v )) produce realistic behavior (drift slow relative to noise), allowing compensation to work well.

**Limitations:**

* Because the true signal ( x_k ) is constant zero, the problem is somewhat simplified; real signals that vary in time may introduce cross-terms and make separation of drift vs signal harder.
* The filter has lag in early time steps; it needs sufficient data to converge. In practice, this means startup or warm-up periods will have poorer performance.
* Assumptions (Gaussian noise, exact drift model, constant ( \sigma_d, \sigma_v )) may not hold in real sensors; mis-specification could degrade performance significantly.
* Since the measurement only senses ( x + d ), observability issues (as seen in Simulink errors) emerged; that must be handled carefully in real implementation.

---

### Comparison with Literature

* Similar works (e.g. *Estimation of Sensor Temperature Drift using Kalman Filter* (IJERT 2014)) report improved settling times, reduced noise, and lower RMSE after Kalman filtering. ([IJERT][1])
* In “An Adaptive Compensation Algorithm for Temperature Drift of MEMS Gyroscopes…” the use of a strong-tracking Kalman filter gives precise drift compensation in changing thermal environments. ([MDPI][2])
* Our findings are aligned: compensation reduces drift and error, especially as time progresses. The literature also notes sensitivity to parameter tuning and initial conditions. ([MDPI][3])

---

### Implications & Recommendations

* For real sensor deployment, ensure sufficient initial calibration or warmup to allow drift estimation to converge.
* Consider introducing small process noise for ( x_k ) if the true signal has dynamics; this helps observability and reduces lag.
* Regularly monitor error metrics (RMSE, MAE) to detect model mis-match. Possibly adapt covariance matrices ( Q, R ) if sensor behavior changes.
* Consider using more complex models (ARIMA, adaptive filters) if drift behavior deviates from random walk, or if measurement noise distributions are non-Gaussian.

---

### Conclusion from Results

Overall, the Kalman filter compensation shows substantial improvement in reducing drift error, aligning estimated drift with true drift, and lowering signal error metrics. While there are limitations and startup effects, the approach works well under the simulated assumptions. This lays groundwork for applying similar methods under more realistic settings (sensor data, varying signals, non-ideal noise).

---

## Defence Commentary Notes

Below are points you might raise in defence, section by section, illustrating understanding or answering likely questions.

| Section                        | Possible Defence Commentary                                                                                                                                                                                                                               |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Simulation Outputs             | “We chose ( \sigma_d = 0.0005 ) and ( \sigma_v = 0.01 ) to make drift small relative to noise early, ensuring the filter has to work—not trivial results. We saw drift dominate only after many steps, matching expected physical behavior of slow bias.” |
| Compensation via Kalman Filter | “Initial lag is expected: the filter needs data to build up its state covariance. We could reduce this lag by nonzero ( \sigma_x ), or by giving some observation of ( x ), or using more informative measurements.”                                      |
| Error Metric Comparisons       | “Large error reduction in RMSE shows that extreme deviations are better corrected; the fact that MAE reduces less suggests residual noise rather than bias is dominant after compensation which is acceptable.”                                           |
| Visualization Insights         | “Histograms centred around zero indicate no bias; symmetry suggests our assumption of zero‐mean noise was okay. Scatter plots show approximate proportionality of ( \hat d ) to true ( d ).”                                                              |
| Strengths & Limitations        | “We must emphasize that the method is robust under ideal assumptions; real data may present nonstationary drift, non-Gaussian noise, missing data, etc. These are topics for future work.”                                                                |
| Comparison with Literature     | “Our work doesn’t yet include temperature dependence or adaptive parameters, but literature shows those improve results in physical experiments—something to consider extending.”                                                                         |
| Implications & Recommendations | “When we implement this method on real sensors, we will need to tune covariances ( Q, R ), maybe adapt them online; possibly combine with ARIMA or machine learning methods for better adaptability.”                                                     |

---

If you like, I can fill in this Results & Discussion section with your actual numbers and graphs so your defence has concrete slides.

[1]: https://www.ijert.org/estimation-of-sensor-temperature-drift-using-kalman-filter?utm_source=chatgpt.com "Estimation of Sensor Temperature Drift using Kalman Filter – IJERT"
[2]: https://www.mdpi.com/1424-8220/15/5/11222?utm_source=chatgpt.com "An Adaptive Compensation Algorithm for Temperature Drift of Micro-Electro-Mechanical Systems Gyroscopes Using a Strong Tracking Kalman Filter"
[3]: https://www.mdpi.com/1424-8220/16/2/235?utm_source=chatgpt.com "Inertial Sensor Error Reduction through Calibration and Sensor Fusion"
