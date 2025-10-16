%% sensor_drift_compensation.m
% Simulate aging-only sensor drift, compensate with Kalman Filter and ARIMA,
% compute RMSE/MAE, and plot results.
% Requires MATLAB. For ARIMA forecasting, Econometrics Toolbox is used (arima, estimate, forecast).
% If not available, a simple trend-fit fallback is provided.

clear; close all; clc;
rng(0); % reproducibility

%% ----- PARAMETERS -----
T = 2000;                 % number of time steps
dt = 1;                   % time step (units arbitrary; e.g., minutes)
t = (0:T-1)'*dt;

% True signal (e.g., slowly varying environment)
% Choose constant or slowly varying (comment/uncomment)
true_const = 25;                   % constant temperature
true_signal = true_const * ones(T,1);
% true_signal = 25 + 0.01*sin(2*pi*t/1440); % example slow cyclical

% Aging-only drift model: random-walk with drift mu
mu = 0.0008;                % deterministic aging per step (mean increment)
sigma_w = 0.01;             % stochastic drift noise (process noise)
sigma_v = 0.1;              % measurement noise (sensor noise)

% Create drift and noisy observations
drift = zeros(T,1);
for k=2:T
    drift(k) = drift(k-1) + mu + sigma_w*randn;
end
y = true_signal + drift + sigma_v*randn(T,1); % observed sensor readings

%% ----- Plot raw data (first look) -----
figure('Name','Raw Data Overview','NumberTitle','off','Units','normalized','Position',[0.1 0.1 0.7 0.6]);
subplot(2,1,1)
plot(t, true_signal, 'k--','LineWidth',1.2); hold on;
plot(t, y, 'Color',[0.7 0 0],'LineWidth',0.6);
legend('True','Observed'); title('True vs Observed (raw)'); xlabel('time'); ylabel('value');
subplot(2,1,2)
plot(t, drift,'b','LineWidth',1.1); title('True Drift (ground truth)'); xlabel('time'); ylabel('drift');

%% ----- 1) KALMAN FILTER IMPLEMENTATION -----
% State vector: x = [s; b] where s = true signal, b = bias/drift
% Dynamics: x_{k+1} = A*x_k + w_k  with w~N(0,Q)
% Measurement: y_k = H*x_k + v_k
A = [1 0; 0 1];         % we model s and b as random walks (could change for known dynamics)
H = [1 1];              % y = s + b + v
% Process & measurement covariances
q_s = 1e-6;             % small process noise for true signal (tune)
q_b = sigma_w^2;        % process noise for bias ≈ variance of drift increment
Q = diag([q_s q_b]);
R = sigma_v^2;          % measurement noise variance

% Initialization
x_est = zeros(2,T);     % filter state estimates
P = eye(2)*1;           % initial covariance (large-ish if uncertain)
x_est(:,1) = [y(1); 0]; % start with observed value for s and 0 bias
P = eye(2)*1;

% Kalman filter loop
for k=2:T
    % Predict
    x_pred = A * x_est(:,k-1);
    P_pred = A * P * A' + Q;
    % Update
    S = H * P_pred * H' + R;
    K = (P_pred * H') / S;                     % Kalman gain (2x1)
    innovation = y(k) - H * x_pred;
    x_est(:,k) = x_pred + K * innovation;
    P = (eye(2) - K*H) * P_pred;
end

y_kf_corr = y - x_est(2,:)'; % corrected reading = observed - estimated bias

%% ----- 2) ARIMA-BASED COMPENSATION -----
% Strategy (simulation): since we have true drift in simulation, we fit ARIMA to drift
% In real use: estimate drift series via baseline or low-pass filter then fit ARIMA.
use_econ = exist('arima','file')==2; % detect econometrics toolbox

if use_econ
    % Fit ARIMA to the (known) drift series
    % difference if necessary: here drift is non-stationary (random walk with drift) -> d=1
    model = arima('Constant',NaN,'AR',NaN,'MA',NaN,'D',1); % just allow estimation
    [estModel, estParamCov, logL] = estimate(model, drift,'Display','off');
    % Forecast drift for one-step ahead (we will produce 1-step forecasts across series)
    % We'll build a rolling forecast for fairness
    drift_hat = zeros(T,1);
    window = 500; % warm-up window for initial fit (increase if needed)
    for k=window+1:T-1
        d_window = drift(1:k); % use past true drift in simulation (in real use use estimated drift)
        try
            m = estimate(arima('D',1,'ARLags',1,'MALags',1), d_window,'Display','off');
            [F,YMSE] = forecast(m,1,'Y0',d_window);
            drift_hat(k+1) = F; % forecast next-step drift
        catch
            % fallback: linear trend extrapolation if estimation fails
            p = polyfit((1:k)', d_window, 1);
            drift_hat(k+1) = polyval(p, k+1);
        end
    end
    % For initial points fill with simple method
    drift_hat(1:window) = movmedian(drift(1:window),max(3,floor(window/10)));
    y_arima_corr = y - drift_hat;
else
    % Econometrics toolbox missing: fallback simple trend estimation (moving average or linear)
    warning('Econometrics toolbox not found. Using simple moving-window trend estimate for ARIMA fallback.');
    drift_hat = movmean(y - true_signal, 50); % moving average estimate of bias (not ARIMA)
    y_arima_corr = y - drift_hat;
end

%% ----- EVALUATION: RMSE and MAE (before and after corrections) -----
rmse = @(a,b) sqrt(mean((a-b).^2));
mae = @(a,b) mean(abs(a-b));

metrics.raw.RMSE = rmse(y, true_signal);
metrics.raw.MAE  = mae(y, true_signal);

metrics.kf.RMSE = rmse(y_kf_corr, true_signal);
metrics.kf.MAE  = mae(y_kf_corr, true_signal);

metrics.arima.RMSE = rmse(y_arima_corr, true_signal);
metrics.arima.MAE  = mae(y_arima_corr, true_signal);

% Display
fprintf('---- Performance (lower is better) ----\n');
fprintf('Raw    : RMSE = %.4f, MAE = %.4f\n', metrics.raw.RMSE, metrics.raw.MAE);
fprintf('Kalman : RMSE = %.4f, MAE = %.4f\n', metrics.kf.RMSE, metrics.kf.MAE);
fprintf('ARIMA  : RMSE = %.4f, MAE = %.4f\n', metrics.arima.RMSE, metrics.arima.MAE);

%% ----- PLOTS: Time series and errors -----
figure('Name','Comparison: True, Raw, KF-corrected, ARIMA-corrected','NumberTitle','off','Units','normalized','Position',[0.1 0.1 0.8 0.6]);
subplot(2,1,1);
plot(t, true_signal, 'k--','LineWidth',1.2); hold on;
plot(t, y, 'Color',[0.8 0 0]); 
plot(t, y_kf_corr, 'b','LineWidth',0.9);
plot(t, y_arima_corr, [0 .5 0],'LineWidth',0.9);
legend('True', 'Observed', 'KF corrected', 'ARIMA corrected','Location','best');
title('Sensor readings: true vs corrected'); xlabel('time'); ylabel('value');

subplot(2,1,2);
plot(t, y - true_signal, 'Color',[0.8 0 0]); hold on;
plot(t, y_kf_corr - true_signal, 'b');
plot(t, y_arima_corr - true_signal, [0 .5 0]);
legend('Raw error','KF error','ARIMA error');
title('Errors (residuals)'); xlabel('time'); ylabel('error');

% Plot estimated bias
figure('Name','Bias estimates','NumberTitle','off','Units','normalized','Position',[0.2 0.2 0.6 0.45]);
plot(t, drift, 'k--','LineWidth',1.1); hold on;
plot(t, x_est(2,:)', 'b','LineWidth',1.1);
if exist('drift_hat','var')
    plot(t, drift_hat, [0 .5 0],'LineWidth',1.1);
    legend('True drift','KF estimate','ARIMA estimate');
else
    legend('True drift','KF estimate');
end
title('True bias vs estimated'); xlabel('time'); ylabel('bias');

%% ----- SAVE / EXPORT results (optional) -----
save_results = true;
if save_results
    save('sensor_drift_results.mat', 't', 'true_signal', 'y', 'drift', 'x_est', 'drift_hat', 'y_kf_corr', 'y_arima_corr', 'metrics');
end

%% ----- END -----
