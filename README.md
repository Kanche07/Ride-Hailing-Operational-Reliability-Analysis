Ride-Hailing Operational Reliability & Fare Integrity Dashboard 

Project Overview 

End-to-end Operational Analytics project analyzing app stability, GPS reliability, fare integrity, and driver churn to identify high-risk app versions and support data-driven hotfix and rollback decisions. 

A hyper-local ride-hailing platform experienced increasing operational challenges due to technical instability within the Driver App. 

Frequent app crashes and GPS lag events began impacting trip tracking accuracy, fare calculations, and overall driver experience. As technical issues increased, fare disputes rose significantly and driver churn accelerated, creating operational and financial risks for the business. 

This project builds a centralized Operational Reliability Dashboard that helps Engineering and Operations teams: 

Monitor app stability 

Identify high-risk app versions 

Detect device and OS-related reliability issues 

Measure fare integrity risk 

Support hotfix and rollback decisions 

Improve driver retention and platform reliability 

 
 

Business Problem 

Challenges 

Increasing app crashes across driver sessions 

Rising GPS lag events affecting trip tracking 

Growing fare calculation errors 

Increasing fare disputes and support workload 

Elevated driver churn across unstable app versions 

Limited visibility into technical root causes 

Business Impact 

Driver dissatisfaction and attrition 

Revenue loss from fare disputes 

Increased driver acquisition costs 

Reduced platform reliability 

Increased operational support effort 

 
 

Dashboard Preview 

App Stability & Reliability Dashboard 

Fare Integrity & Driver Impact Dashboard 

 
 

Key Objectives 

Centralize app stability and fare integrity metrics into a single dashboard 

Identify high-risk app versions requiring intervention 

Detect device and OS combinations contributing to instability 

Measure the impact of GPS issues on fare accuracy 

Quantify revenue exposure from fare disputes 

Support data-driven hotfix and rollback decisions 

Improve driver retention and operational reliability 

 
 

Key KPIs 

KPI 

Description 

Crash Rate 

Percentage of app sessions experiencing crashes 

GPS Lag Rate 

Percentage of sessions affected by GPS lag 

Driver Churn Rate 

Percentage of drivers leaving the platform 

Fare Dispute Rate 

Percentage of trips resulting in disputes 

Revenue at Risk 

Financial exposure from disputed fares 

High-Risk Versions 

App versions exceeding stability thresholds 

Affected Sessions 

Sessions impacted by app crashes 

Fare Error Rate 

Percentage of trips with incorrect fare calculations 

 
 

Executive Summary 

Overall Crash Rate reached 14.96% 

Overall GPS Lag Rate reached 20.60% 

Driver Churn Rate increased to 24.10% 

Fare Dispute Rate reached 19.98% 

Revenue at Risk exceeded $254K 

App Versions 2.3.1 and 2.4.0 recorded the highest operational risk scores 

GPS-affected trips generated a 47.32% Fare Error Rate 

Versions 2.3.1 and 2.4.0 recorded Fare Error Rates above 55% 

Driver Churn exceeded 32% on high-risk versions 

Analysis identified a strong relationship between app instability, fare disputes, and driver attrition 

 
 

Key Findings 

1. Versions 2.3.1 and 2.4.0 Drive Most Operational Risk 

These versions recorded the highest crash rates, GPS lag rates, fare error rates, dispute rates, and driver churn rates, making them the primary contributors to platform instability. 

2. GPS Issues Are The Primary Cause Of Fare Errors 

Trips affected by GPS issues experienced a 47.32% fare error rate compared to only 4.88% for trips without GPS issues. 

3. Driver Churn Is Concentrated In High-Risk Versions 

Versions 2.3.1 and 2.4.0 recorded churn rates above 32%, significantly higher than all other versions. 

4. Fare Integrity Problems Are Concentrated In Specific Releases 

Versions 2.3.1 and 2.4.0 generated fare error rates above 55%, creating substantial operational and financial risk. 

5. Device-Level Stability Issues Exist 

Realme 8, Redmi Note 10, and Samsung Galaxy M31 recorded the highest crash rates among major devices. 

6. GPS-Related Features Generate Most Technical Events 

Navigation, Fare Meter, and Map features recorded the highest GPS dropout event volumes, indicating that location services are a major source of operational disruption. 

7. Revenue Risk Is Closely Linked To Technical Instability 

GPS-related fare errors and unstable app versions contributed significantly to disputed fares and revenue exposure. 

 
 

Recommendations 

Prioritize hotfixes for app versions 2.3.1 and 2.4.0 

Improve GPS stability and trip tracking reliability 

Introduce fare calculation validation testing before release 

Expand device compatibility testing for high-risk Android devices 

Implement version-level risk monitoring before deployment 

Monitor dispute concentration across high-risk cities 

Use operational risk scores to support release and rollback decisions 

 
 

Expected Business Outcomes 

Reduce fare disputes by at least 25% 

Reduce driver churn 

Improve app stability across Android and iOS devices 

Reduce revenue exposure from fare inaccuracies 

Improve fare calculation reliability 

Improve driver satisfaction and retention 

Strengthen release governance through risk-based monitoring 

Improve overall platform reliability and customer trust 

 
 

Tools & Technologies 

PostgreSQL (SQL) 

Python 

Tableau 

Data Visualization 

KPI Design 

Root Cause Analysis 

Operational Analytics 
