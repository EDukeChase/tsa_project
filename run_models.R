library(forecast)
library(here)
library(dplyr)

# Job 1:
sarima_d0_D0 <- auto.arima(train_ts, d=0, D=0, 
                           stepwise=FALSE, approximation=FALSE, lambda="auto", trace=TRUE)
saveRDS(sarima_d0_D0, here("data", "sarima_d0_D0.rds"))

# Job 2: 
sarima_d0_D1 <- auto.arima(train_ts, d=0, D=1, 
                           stepwise=FALSE, approximation=FALSE, lambda="auto", trace=TRUE)
saveRDS(sarima_d0_D1, here("data", "sarima_d0_D1.rds"))

# Job 3: 
sarima_d1_D0 <- auto.arima(train_ts, d=1, D=0, 
                           stepwise=FALSE, approximation=FALSE, lambda="auto", trace=TRUE)
saveRDS(sarima_d1_D0, here("data", "sarima_d1_D0.rds"))

# Job 4: 
sarima_d1_D1 <- auto.arima(train_ts, d=1, D=1, 
                           stepwise=FALSE, approximation=FALSE, lambda="auto", trace=TRUE)
saveRDS(sarima_d1_D1, here("data", "sarima_d1_D1.rds"))