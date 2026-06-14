-- TABLE 1: DRIVERS
CREATE TABLE drivers (
    driver_id        INT PRIMARY KEY,
    city             VARCHAR(50),
    device_model     VARCHAR(50),
    os_type          VARCHAR(20),
    os_version       VARCHAR(30),
    app_version      VARCHAR(20),
    onboarding_date  DATE,
    status           VARCHAR(20)
);

-- TABLE 2: APP_SESSIONS
CREATE TABLE app_sessions (
    session_id            INT PRIMARY KEY,
    driver_id             INT,
    app_version           VARCHAR(20),
    os_version            VARCHAR(30),
    device_model          VARCHAR(50),
    session_start         TIMESTAMP,
    session_duration_mins INT,
    crash_count           INT,
    gps_lag_events        INT,
    anr_count             INT,
    session_outcome       VARCHAR(30),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

-- TABLE 3: APP_EVENTS
CREATE TABLE app_events (
    event_id         INT PRIMARY KEY,
    session_id       INT,
    event_type       VARCHAR(30),
    event_time       TIMESTAMP,
    severity         INT,
    error_code       VARCHAR(30),
    affected_feature VARCHAR(50),
    FOREIGN KEY (session_id) REFERENCES app_sessions(session_id)
);

-- TABLE 4: TRIPS
CREATE TABLE trips (
    trip_id             INT PRIMARY KEY,
    driver_id           INT,
    session_id          INT,
    trip_start          TIMESTAMP,
    trip_end            TIMESTAMP,
    trip_duration_mins  INT,
    distance_km         NUMERIC(6,2),
    calculated_fare     NUMERIC(8,2),
    charged_fare        NUMERIC(8,2),
    fare_difference     NUMERIC(8,2),
    fare_status         VARCHAR(20),
    gps_accuracy_avg    NUMERIC(5,2),
    gps_dropout_count   INT,
    city                VARCHAR(50),
    FOREIGN KEY (driver_id)  REFERENCES drivers(driver_id),
    FOREIGN KEY (session_id) REFERENCES app_sessions(session_id)
);

-- TABLE 5: FARE_DISPUTES
CREATE TABLE fare_disputes (
    dispute_id        INT PRIMARY KEY,
    trip_id           INT,
    dispute_raised    TIMESTAMP,
    dispute_reason    VARCHAR(50),
    disputed_amount   NUMERIC(8,2),
    resolution_status VARCHAR(30),
    resolution_days   INT,
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
);


/* =========================================================
SECTION 1: PROBLEM VALIDATION
Business Question: Is platform reliability deteriorating?
========================================================= */
 
--1. App crash rate by app_version
select 
   app_version,
   count(distinct session_id) as total_sessions, 
   count (
      distinct case
            when crash_count > 0
			then session_id
		end
   ) as crashed_sessions,
   round(
   count(
      distinct case 
            when crash_count > 0 
			then session_id
		end
     ) * 100.0
       /
   count(distinct session_id),
   2
   ) as crash_rate
 from app_sessions
 group by app_version
 order by crash_rate desc

-- 2. GPS Lag Rate by App Version
SELECT
    app_version,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(
        DISTINCT CASE
            WHEN gps_lag_events > 0
            THEN session_id
        END
    ) AS gps_lag_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN gps_lag_events > 0
                THEN session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT session_id),
        2
    ) AS gps_lag_rate
FROM app_sessions
GROUP BY app_version
ORDER BY gps_lag_rate DESC;

-- 3. Monthly Crash Rate Trend
SELECT
    DATE_TRUNC('month', session_start) AS month,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(
        DISTINCT CASE
            WHEN crash_count > 0
            THEN session_id
        END
    ) AS crashed_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN crash_count > 0
                THEN session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT session_id),
        2
    ) AS crash_rate
FROM app_sessions
GROUP BY DATE_TRUNC('month', session_start)
ORDER BY month;


/* =========================================================
SECTION 2: IDENTIFY TECHNICAL ROOT CAUSE
Hypothesis: Specific App Version + OS combinations
are causing instability.
========================================================= */

-- 4. Crash Rate by App Version ,OS Type , OS Version
SELECT
    s.app_version,
    d.os_type,
    s.os_version,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    COUNT(
        DISTINCT CASE
            WHEN s.crash_count > 0
            THEN s.session_id
        END
    ) AS crashed_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN s.crash_count > 0
                THEN s.session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT s.session_id),
        2
    ) AS crash_rate
FROM app_sessions s
JOIN drivers d
ON s.driver_id = d.driver_id
GROUP BY
    s.app_version,
    d.os_type,
    s.os_version
HAVING COUNT(DISTINCT s.session_id) >= 30
ORDER BY crash_rate DESC

-- 5. Device-Level Stability Analysis
SELECT
    device_model,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(
        DISTINCT CASE
            WHEN crash_count > 0
            THEN session_id
        END
    ) AS crashed_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN crash_count > 0
                THEN session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT session_id),
        2
    ) AS crash_rate,
    COUNT(
        DISTINCT CASE
            WHEN gps_lag_events > 0
            THEN session_id
        END
    ) AS gps_issue_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN gps_lag_events > 0
                THEN session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT session_id),
        2
    ) AS gps_issue_rate,
    COUNT(
        DISTINCT CASE
            WHEN anr_count > 0
            THEN session_id
        END
    ) AS anr_sessions,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN anr_count > 0
                THEN session_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT session_id),
        2
    ) AS anr_rate
FROM app_sessions
GROUP BY device_model
HAVING COUNT(DISTINCT session_id) >= 50
ORDER BY crash_rate DESC;


-- 6. Top Affected Features by Event Type & Severity
SELECT
    ae.event_type,
    ae.affected_feature,
    COUNT(DISTINCT ae.event_id) AS total_events,
    ROUND(AVG(ae.severity), 2) AS avg_severity,
    COUNT(DISTINCT ae.session_id) AS affected_sessions
FROM app_events ae
GROUP BY ae.event_type, ae.affected_feature
ORDER BY total_events DESC;

/* =========================================================
SECTION 3: FARE INTEGRITY IMPACT ANALYSIS
Hypothesis: Technical issues are contributing
to fare calculation errors.
========================================================= */

-- 7. GPS Error Impact on Fare Integrity
SELECT
    CASE
        WHEN t.gps_dropout_count > 0
        THEN 'GPS Issue'
        ELSE 'No GPS Issue'
    END AS gps_condition,
    COUNT(DISTINCT t.trip_id) AS total_trips,
    COUNT(
        DISTINCT CASE
            WHEN t.fare_status != 'correct'
            THEN t.trip_id
        END
    ) AS fare_error_trips,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN t.fare_status != 'correct'
                THEN t.trip_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT t.trip_id),
        2
    ) AS fare_error_rate,
    ROUND(
        SUM(
            CASE
                WHEN t.fare_status != 'correct'
                THEN ABS(t.fare_difference)
                ELSE 0
            END
        ),
        2
    ) AS revenue_at_risk
FROM trips t
GROUP BY
    CASE
        WHEN t.gps_dropout_count > 0
        THEN 'GPS Issue'
        ELSE 'No GPS Issue'
    END
ORDER BY fare_error_rate DESC;


--8. Fare Error Rate + Revenue at Risk by App Version
SELECT
    s.app_version,
    COUNT(DISTINCT t.trip_id) AS total_trips,
    COUNT(
        DISTINCT CASE
            WHEN t.fare_status != 'correct'
            THEN t.trip_id
        END
    ) AS fare_error_trips,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN t.fare_status != 'correct'
                THEN t.trip_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT t.trip_id),
        2
    ) AS fare_error_rate,
    ROUND(
        SUM(
            CASE
                WHEN t.fare_status != 'correct'
                THEN ABS(t.fare_difference)
                ELSE 0
            END
        ),
        2
    ) AS revenue_at_risk
FROM trips t
JOIN app_sessions s
ON t.session_id = s.session_id
GROUP BY s.app_version
ORDER BY fare_error_rate DESC;

--9. Fare Dispute Rate by App Version
with dispute_summary as (
     select 
	 s.app_version,
	 count(distinct f.dispute_id) as total_disputes
   from fare_disputes f
    join trips t
    on f.trip_id = t.trip_id
    join app_sessions s
    on t.session_id = s.session_id
    group by s.app_version
),
trip_summary as (
     select 
	 s.app_version,
	 count(distinct trip_id) as total_trips
     from trips t
     join app_sessions s
     on t.session_id = s.session_id
   group by app_version
 )
     select 
	  t.app_version,
	  t.total_trips,
	  coalesce(d.total_disputes, 0) as total_disputes,
	  round(
           coalesce(d.total_disputes, 0) * 100.0
	       /
	       t.total_trips, 
	       2 
	) as dispute_rate
from trip_summary t
left join dispute_summary d
on t.app_version = d.app_version
order by dispute_rate desc

/* =========================================================
SECTION 4: CUSTOMER SUPPORT & DISPUTE ANALYSIS
Hypothesis: Technical failures are increasing
support workload and dispute volume.
========================================================= */

--10. Error → Dispute Conversion Rate
WITH error_trips AS (
    SELECT DISTINCT
        t.trip_id,
        s.app_version
    FROM trips t
    JOIN app_sessions s
    ON t.session_id = s.session_id
    WHERE
        t.fare_status != 'correct'
        OR
        t.gps_dropout_count > 0
        OR
        s.crash_count > 0
),
disputed_error_trips AS (
    SELECT DISTINCT
        e.trip_id,
        e.app_version
    FROM error_trips e
    JOIN fare_disputes f
    ON e.trip_id = f.trip_id
)
SELECT
    e.app_version,
    COUNT(DISTINCT e.trip_id) AS total_error_trips,
    COUNT(DISTINCT d.trip_id) AS disputed_error_trips,
    ROUND(
        COUNT(DISTINCT d.trip_id) * 100.0
        /
        COUNT(DISTINCT e.trip_id),
        2
    ) AS error_to_dispute_conversion_rate
FROM error_trips e
LEFT JOIN disputed_error_trips d
ON e.trip_id = d.trip_id
GROUP BY e.app_version
ORDER BY error_to_dispute_conversion_rate DESC;


-- 11. MTTR (Mean Time To Resolution) by Dispute Reason
SELECT
    dispute_reason,
    COUNT(DISTINCT dispute_id) AS resolved_disputes,
    ROUND(
        AVG(resolution_days),
        2
    ) AS avg_resolution_days,
    MIN(resolution_days) AS fastest_resolution,
    MAX(resolution_days) AS slowest_resolution
FROM fare_disputes
WHERE resolution_status = 'resolved'
GROUP BY dispute_reason
ORDER BY avg_resolution_days DESC;

-- 12. City-wise Dispute Concentration
WITH dispute_summary AS (
    SELECT
        t.city,
        COUNT(DISTINCT f.dispute_id) AS total_disputes
    FROM fare_disputes f
    JOIN trips t
    ON f.trip_id = t.trip_id
    GROUP BY t.city
),
trip_summary AS (
    SELECT
        city,
        COUNT(DISTINCT trip_id) AS total_trips
    FROM trips
    GROUP BY city
)
SELECT
    ts.city,
    ts.total_trips,
    COALESCE(ds.total_disputes, 0) AS total_disputes,
    ROUND(
        COALESCE(ds.total_disputes, 0) * 100.0
        /
        ts.total_trips,
        2
    ) AS dispute_rate
FROM trip_summary ts
LEFT JOIN dispute_summary ds
ON ts.city = ds.city
ORDER BY dispute_rate DESC;

/* =========================================================
SECTION 5: DRIVER CHURN ANALYSIS
Hypothesis: Unstable app versions are driving
driver dissatisfaction and churn.
========================================================= */

--13. Driver Churn rate by App version
with latest_version as(
  select
    driver_id, 
	app_version,
	session_start,
	row_number() over(
    partition by driver_id
	order by session_start desc
   ) as rn
   from app_sessions
)
 select
 lv.app_version,
 count(distinct d.driver_id) as total_drivers,
 count(distinct case
                when d.status = 'churned'
				then d.driver_id
			end) as churned_drivers,
  round(
      count(distinct case 
	            when d.status = 'churned'
				then d.driver_id
				end) * 100.0
			   / 
			   count(distinct d.driver_id), 2
			) as churn_rate
from drivers d
join latest_version lv
on d.driver_id = lv.driver_id
where lv.rn = 1
group by lv.app_version
order by churn_rate desc

/* =========================================================
SECTION 6: HIGH-RISK VERSION DETECTION
Purpose: Identify app versions requiring
immediate intervention.
========================================================= */

-- 14. High-Risk Version Detection
WITH crash_metrics AS (
    SELECT
        app_version,
        ROUND(
            COUNT(
                DISTINCT CASE
                    WHEN crash_count > 0
                    THEN session_id
                END
            ) * 100.0
            /
            COUNT(DISTINCT session_id),
            2
        ) AS crash_rate
    FROM app_sessions
    GROUP BY app_version
),

gps_metrics AS (
    SELECT
        app_version,
        ROUND(
            COUNT(
                DISTINCT CASE
                    WHEN gps_lag_events > 0
                    THEN session_id
                END
            ) * 100.0
            /
            COUNT(DISTINCT session_id),
            2
        ) AS gps_lag_rate
    FROM app_sessions
    GROUP BY app_version
),

fare_metrics AS (
    SELECT
        s.app_version,
        ROUND(
            COUNT(
                DISTINCT CASE
                    WHEN t.fare_status != 'correct'
                    THEN t.trip_id
                END
            ) * 100.0
            /
            COUNT(DISTINCT t.trip_id),
            2
        ) AS fare_error_rate
    FROM trips t
    JOIN app_sessions s
    ON t.session_id = s.session_id
    GROUP BY s.app_version
),

dispute_metrics AS (
    SELECT
        s.app_version,
        ROUND(
            COUNT(DISTINCT f.dispute_id) * 100.0
            /
            COUNT(DISTINCT t.trip_id),
            2
        ) AS dispute_rate
    FROM trips t
    JOIN app_sessions s
    ON t.session_id = s.session_id
    LEFT JOIN fare_disputes f
    ON t.trip_id = f.trip_id
    GROUP BY s.app_version

),
churn_metrics AS (
    WITH latest_version AS (
        SELECT
            driver_id,
            app_version,
            session_start,
            ROW_NUMBER() OVER (
                PARTITION BY driver_id
                ORDER BY session_start DESC
            ) AS rn
        FROM app_sessions
    )
    SELECT
        lv.app_version,
        ROUND(
            COUNT(
                DISTINCT CASE
                    WHEN d.status = 'churned'
                    THEN d.driver_id
                END
            ) * 100.0
            /
            COUNT(DISTINCT d.driver_id),
            2
        ) AS churn_rate
    FROM drivers d
    JOIN latest_version lv
    ON d.driver_id = lv.driver_id
    WHERE lv.rn = 1
    GROUP BY lv.app_version
)
SELECT
    c.app_version,
    c.crash_rate,
    g.gps_lag_rate,
    f.fare_error_rate,
    d.dispute_rate,
    ch.churn_rate,
    ROUND(
        (
            c.crash_rate
            + g.gps_lag_rate
            + f.fare_error_rate
            + d.dispute_rate
            + ch.churn_rate
        ) / 5,
        2
    ) AS overall_risk_score
FROM crash_metrics c
JOIN gps_metrics g
ON c.app_version = g.app_version
JOIN fare_metrics f
ON c.app_version = f.app_version
JOIN dispute_metrics d
ON c.app_version = d.app_version
JOIN churn_metrics ch
ON c.app_version = ch.app_version
ORDER BY overall_risk_score DESC;




/* =========================================================
SECTION 7: EXECUTIVE KPI DASHBOARD
Purpose: Provide Engineering and Operations
teams with decision-making KPIs.
========================================================= */

--Technical Root Cause Analysis View

CREATE OR REPLACE VIEW engineering_dashboard_kpi AS

WITH crash_metrics AS (
    SELECT
        ROUND(
            COUNT(DISTINCT CASE
                WHEN crash_count > 0
                THEN session_id
            END) * 100.0
            /
            COUNT(DISTINCT session_id),
            2
        ) AS overall_crash_rate,

        COUNT(DISTINCT CASE
            WHEN crash_count > 0
            THEN session_id
        END) AS affected_sessions

    FROM app_sessions
),

gps_metrics AS (
    SELECT
        ROUND(
            COUNT(DISTINCT CASE
                WHEN gps_lag_events > 0
                THEN session_id
            END) * 100.0
            /
            COUNT(DISTINCT session_id),
            2
        ) AS overall_gps_lag_rate

    FROM app_sessions
),

high_risk_versions AS (
    SELECT
        COUNT(*) AS high_risk_versions
    FROM (

        WITH crash_metrics AS (
            SELECT
                app_version,
                ROUND(
                    COUNT(
                        DISTINCT CASE
                            WHEN crash_count > 0
                            THEN session_id
                        END
                    ) * 100.0
                    /
                    COUNT(DISTINCT session_id),
                    2
                ) AS crash_rate
            FROM app_sessions
            GROUP BY app_version
        ),

        gps_metrics AS (
            SELECT
                app_version,
                ROUND(
                    COUNT(
                        DISTINCT CASE
                            WHEN gps_lag_events > 0
                            THEN session_id
                        END
                    ) * 100.0
                    /
                    COUNT(DISTINCT session_id),
                    2
                ) AS gps_lag_rate
            FROM app_sessions
            GROUP BY app_version
        )

        SELECT
            c.app_version
        FROM crash_metrics c
        JOIN gps_metrics g
        ON c.app_version = g.app_version

        WHERE
            c.crash_rate > 15
            OR
            g.gps_lag_rate > 15

    ) x
)

SELECT
    c.overall_crash_rate,
    g.overall_gps_lag_rate,
    h.high_risk_versions,
    c.affected_sessions

FROM crash_metrics c
CROSS JOIN gps_metrics g
CROSS JOIN high_risk_versions h;

select * from engineering_dashboard_kpi



--Business Impact & Risk Analysis View

CREATE OR REPLACE VIEW operations_dashboard_kpi AS

WITH churn_metrics AS (

    SELECT

        ROUND(
            COUNT(
                CASE
                    WHEN LOWER(status) = 'churned'
                    THEN 1
                END
            ) * 100.0
            /
            COUNT(*),
            2
        ) AS overall_churn_rate,

        COUNT(
            CASE
                WHEN LOWER(status) = 'churned'
                THEN 1
            END
        ) AS churned_drivers

    FROM drivers

),

fare_metrics AS (

    SELECT

        ROUND(
            COUNT(DISTINCT fd.trip_id) * 100.0
            /
            COUNT(DISTINCT t.trip_id),
            2
        ) AS fare_dispute_rate,

        COUNT(DISTINCT fd.dispute_id) AS total_fare_disputes,

        ROUND(
            SUM(fd.disputed_amount),
            2
        ) AS revenue_at_risk

    FROM trips t

    LEFT JOIN fare_disputes fd
        ON t.trip_id = fd.trip_id

)

SELECT

    c.overall_churn_rate,
    c.churned_drivers,

    f.fare_dispute_rate,
    f.total_fare_disputes,
    f.revenue_at_risk

FROM churn_metrics c
CROSS JOIN fare_metrics f;

select * from operations_dashboard_kpi


--Driver Retention & Churn View

CREATE OR REPLACE VIEW operations_dashboard_kpi AS


SELECT
    ROUND(
        COUNT(DISTINCT CASE
            WHEN LOWER(status) = 'churned'
            THEN driver_id
        END) * 100.0
        /
        COUNT(DISTINCT driver_id),
        2
    ) AS driver_churn_rate,

    COUNT(DISTINCT CASE
        WHEN LOWER(status) = 'churned'
        THEN driver_id
    END) AS churned_drivers

FROM drivers;

