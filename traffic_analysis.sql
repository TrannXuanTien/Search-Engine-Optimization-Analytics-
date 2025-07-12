-- Step 1: Daily traffic analysis
CREATE TABLE analytics.daily_traffic_analysis AS (
    WITH daily_stats AS (
        SELECT 
            CAST(visit_datetime AS DATE) as traffic_date,
            COUNT(*) as total_visits,
            COUNT(DISTINCT user_id) as unique_visitors,
            COUNT(DISTINCT session_id) as unique_sessions,
            SUM(page_views) as total_page_views,
            AVG(session_duration) as avg_session_duration,
            SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
            
            -- Traffic by source
            COUNT(CASE WHEN traffic_source_clean = 'Direct' THEN 1 END) as direct_visits,
            COUNT(CASE WHEN traffic_source_clean = 'Search Engine' THEN 1 END) as search_visits,
            COUNT(CASE WHEN traffic_source_clean = 'Social Media' THEN 1 END) as social_visits,
            COUNT(CASE WHEN traffic_source_clean = 'Referral' THEN 1 END) as referral_visits,
            
            -- Traffic by device
            COUNT(CASE WHEN device_category = 'Desktop' THEN 1 END) as desktop_visits,
            COUNT(CASE WHEN device_category = 'Mobile' THEN 1 END) as mobile_visits,
            COUNT(CASE WHEN device_category = 'Tablet' THEN 1 END) as tablet_visits,
            
            -- Page categories
            COUNT(CASE WHEN page_category = 'Blog' THEN 1 END) as blog_visits,
            COUNT(CASE WHEN page_category = 'Online Learning' THEN 1 END) as learning_visits,
            COUNT(CASE WHEN page_category = 'Registration' THEN 1 END) as registration_visits,
            COUNT(CASE WHEN page_category = 'Homepage' THEN 1 END) as homepage_visits
            
        FROM clean.traffic_data
        GROUP BY CAST(visit_datetime AS DATE)
    )
    
    SELECT 
        traffic_date,
        total_visits,
        unique_visitors,
        unique_sessions,
        total_page_views,
        ROUND(avg_session_duration, 2) as avg_session_duration,
        bounce_visits,
        ROUND((bounce_visits * 100.0 / total_visits), 2) as bounce_rate_pct,
        ROUND((total_page_views * 1.0 / unique_sessions), 2) as pages_per_session,
        
        -- Traffic source percentages
        ROUND((direct_visits * 100.0 / total_visits), 2) as direct_pct,
        ROUND((search_visits * 100.0 / total_visits), 2) as search_pct,
        ROUND((social_visits * 100.0 / total_visits), 2) as social_pct,
        ROUND((referral_visits * 100.0 / total_visits), 2) as referral_pct,
        
        -- Device percentages
        ROUND((desktop_visits * 100.0 / total_visits), 2) as desktop_pct,
        ROUND((mobile_visits * 100.0 / total_visits), 2) as mobile_pct,
        ROUND((tablet_visits * 100.0 / total_visits), 2) as tablet_pct,
        
        -- Page category visits
        blog_visits,
        learning_visits,
        registration_visits,
        homepage_visits,
        
        -- Day over day growth
        LAG(total_visits) OVER (ORDER BY traffic_date) as prev_day_visits,
        CASE 
            WHEN LAG(total_visits) OVER (ORDER BY traffic_date) IS NOT NULL 
            THEN ROUND(((total_visits - LAG(total_visits) OVER (ORDER BY traffic_date)) * 100.0 / 
                       LAG(total_visits) OVER (ORDER BY traffic_date)), 2)
            ELSE NULL
        END as day_over_day_growth_pct
        
    FROM daily_stats
    ORDER BY traffic_date
);

-- Step 2: Hourly traffic patterns
CREATE TABLE analytics.hourly_traffic_patterns AS (
    SELECT 
        visit_hour,
        COUNT(*) as total_visits,
        COUNT(DISTINCT user_id) as unique_visitors,
        AVG(session_duration) as avg_session_duration,
        SUM(page_views) as total_page_views,
        
        -- By user category
        COUNT(CASE WHEN u.user_category = 'Student' THEN 1 END) as student_visits,
        COUNT(CASE WHEN u.user_category = 'Corporate' THEN 1 END) as corporate_visits,
        COUNT(CASE WHEN u.user_category = 'Personal' THEN 1 END) as personal_visits,
        
        -- By page category
        COUNT(CASE WHEN t.page_category = 'Blog' THEN 1 END) as blog_visits,
        COUNT(CASE WHEN t.page_category = 'Online Learning' THEN 1 END) as learning_visits,
        COUNT(CASE WHEN t.page_category = 'Registration' THEN 1 END) as registration_visits,
        
        -- Calculate percentage of daily traffic
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as pct_of_daily_traffic,
        
        -- Peak indicator
        CASE 
            WHEN visit_hour IN (9, 12, 15, 21, 22) THEN 'Peak Hour'
            WHEN visit_hour BETWEEN 9 AND 17 THEN 'Business Hours'
            WHEN visit_hour BETWEEN 18 AND 23 THEN 'Evening Hours'
            ELSE 'Off Hours'
        END as hour_category
        
    FROM clean.traffic_data t
    LEFT JOIN clean.user_registrations u ON t.user_id = u.user_id
    GROUP BY visit_hour
    ORDER BY visit_hour
);

-- Step 3: Traffic source performance analysis
CREATE TABLE analytics.traffic_source_analysis AS (
    WITH source_metrics AS (
        SELECT 
            traffic_source_clean,
            COUNT(*) as total_visits,
            COUNT(DISTINCT user_id) as unique_visitors,
            COUNT(DISTINCT session_id) as unique_sessions,
            SUM(page_views) as total_page_views,
            AVG(session_duration) as avg_session_duration,
            SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
            
            -- Registration conversions
            COUNT(CASE WHEN page_category = 'Registration' THEN 1 END) as registration_page_visits,
            
            -- Content engagement
            COUNT(CASE WHEN page_category = 'Blog' THEN 1 END) as blog_visits,
            COUNT(CASE WHEN page_category = 'Online Learning' THEN 1 END) as learning_visits
            
        FROM clean.traffic_data
        GROUP BY traffic_source_clean
    ),
    
    registrations_by_source AS (
        SELECT 
            t.traffic_source_clean,
            COUNT(DISTINCT u.user_id) as completed_registrations
        FROM clean.traffic_data t
        JOIN clean.user_registrations u ON t.user_id = u.user_id
        WHERE t.page_category = 'Registration'
        GROUP BY t.traffic_source_clean
    )
    
    SELECT 
        sm.traffic_source_clean,
        sm.total_visits,
        sm.unique_visitors,
        sm.unique_sessions,
        ROUND(sm.avg_session_duration, 2) as avg_session_duration,
        ROUND((sm.bounce_visits * 100.0 / sm.total_visits), 2) as bounce_rate_pct,
        ROUND((sm.total_page_views * 1.0 / sm.unique_sessions), 2) as pages_per_session,
        
        -- Conversion metrics
        sm.registration_page_visits,
        COALESCE(rbs.completed_registrations, 0) as completed_registrations,
        CASE 
            WHEN sm.registration_page_visits > 0 
            THEN ROUND((COALESCE(rbs.completed_registrations, 0) * 100.0 / sm.registration_page_visits), 2)
            ELSE 0
        END as registration_conversion_rate,
        
        -- Content engagement
        sm.blog_visits,
        sm.learning_visits,
        ROUND((sm.blog_visits * 100.0 / sm.total_visits), 2) as blog_engagement_pct,
        ROUND((sm.learning_visits * 100.0 / sm.total_visits), 2) as learning_engagement_pct,
        
        -- Traffic share
        ROUND((sm.total_visits * 100.0 / SUM(sm.total_visits) OVER()), 2) as traffic_share_pct,
        
        -- Quality score (combination of engagement metrics)
        ROUND((
            (100 - LEAST((sm.bounce_visits * 100.0 / sm.total_visits), 100)) * 0.3 +
            LEAST((sm.total_page_views * 1.0 / sm.unique_sessions), 10) * 10 * 0.3 +
            LEAST((sm.avg_session_duration / 60), 10) * 10 * 0.4
        ), 2) as quality_score
        
    FROM source_metrics sm
    LEFT JOIN registrations_by_source rbs ON sm.traffic_source_clean = rbs.traffic_source_clean
    ORDER BY sm.total_visits DESC
);

-- Step 4: Page performance analysis
CREATE TABLE analytics.page_performance_analysis AS (
    WITH page_metrics AS (
        SELECT 
            page_category,
            COUNT(*) as total_visits,
            COUNT(DISTINCT user_id) as unique_visitors,
            COUNT(DISTINCT session_id) as unique_sessions,
            AVG(session_duration) as avg_session_duration,
            SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
            
            -- Time spent metrics from content interactions
            AVG(c.time_spent_clean) as avg_time_on_page,
            AVG(c.completion_rate_clean) as avg_completion_rate,
            
            -- User segment breakdown
            COUNT(CASE WHEN u.user_category = 'Student' THEN 1 END) as student_visits,
            COUNT(CASE WHEN u.user_category = 'Corporate' THEN 1 END) as corporate_visits,
            COUNT(CASE WHEN u.user_category = 'Personal' THEN 1 END) as personal_visits
            
        FROM clean.traffic_data t
        LEFT JOIN clean.user_registrations u ON t.user_id = u.user_id
        LEFT JOIN clean.content_interactions c ON t.user_id = c.user_id 
            AND t.page_category = CASE 
                WHEN c.content_type_clean = 'Blog' THEN 'Blog'
                WHEN c.content_type_clean = 'Course' THEN 'Online Learning'
                ELSE 'Other'
            END
        GROUP BY page_category
    )
    
    SELECT 
        page_category,
        total_visits,
        unique_visitors,
        unique_sessions,
        ROUND(avg_session_duration, 2) as avg_session_duration_sec,
        ROUND((bounce_visits * 100.0 / total_visits), 2) as bounce_rate_pct,
        ROUND(COALESCE(avg_time_on_page, 0), 2) as avg_time_on_page_sec,
        ROUND(COALESCE(avg_completion_rate, 0), 2) as avg_completion_rate_pct,
        
        -- User segment percentages
        ROUND((student_visits * 100.0 / total_visits), 2) as student_pct,
        ROUND((corporate_visits * 100.0 / total_visits), 2) as corporate_pct,
        ROUND((personal_visits * 100.0 / total_visits), 2) as personal_pct,
        
        -- Page popularity
        ROUND((total_visits * 100.0 / SUM(total_visits) OVER()), 2) as page_share_pct,
        
        -- Page performance score
        ROUND((
            (100 - LEAST((bounce_visits * 100.0 / total_visits), 100)) * 0.4 +
            LEAST((avg_session_duration / 60), 10) * 10 * 0.3 +
            LEAST(COALESCE(avg_completion_rate, 0), 100) * 0.3
        ), 2) as performance_score
        
    FROM page_metrics
    ORDER BY total_visits DESC
);

-- Step 5: Weekly trend analysis
CREATE TABLE analytics.weekly_trends AS (
    SELECT 
        visit_week,
        weekday_name,
        COUNT(*) as total_visits,
        COUNT(DISTINCT user_id) as unique_visitors,
        AVG(session_duration) as avg_session_duration,
        SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
        
        -- Compare to previous week
        LAG(COUNT(*)) OVER (PARTITION BY weekday_name ORDER BY visit_week) as prev_week_visits,
        CASE 
            WHEN LAG(COUNT(*)) OVER (PARTITION BY weekday_name ORDER BY visit_week) IS NOT NULL
            THEN ROUND(((COUNT(*) - LAG(COUNT(*)) OVER (PARTITION BY weekday_name ORDER BY visit_week)) * 100.0 / 
                       LAG(COUNT(*)) OVER (PARTITION BY weekday_name ORDER BY visit_week)), 2)
            ELSE NULL
        END as week_over_week_growth_pct
        
    FROM clean.traffic_data
    GROUP BY visit_week, weekday_name
    ORDER BY visit_week, 
        CASE weekday_name 
            WHEN 'Monday' THEN 1 
            WHEN 'Tuesday' THEN 2 
            WHEN 'Wednesday' THEN 3 
            WHEN 'Thursday' THEN 4 
            WHEN 'Friday' THEN 5 
            WHEN 'Saturday' THEN 6 
            WHEN 'Sunday' THEN 7 
        END
);

-- Step 6: Bounce rate analysis by various dimensions
CREATE TABLE analytics.bounce_rate_analysis AS (
    SELECT 
        'Overall' as dimension,
        'All Traffic' as dimension_value,
        COUNT(*) as total_visits,
        SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
        ROUND((SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as bounce_rate_pct
    FROM clean.traffic_data
    
    UNION ALL
    
    SELECT 
        'Traffic Source' as dimension,
        traffic_source_clean as dimension_value,
        COUNT(*) as total_visits,
        SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
        ROUND((SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as bounce_rate_pct
    FROM clean.traffic_data
    GROUP BY traffic_source_clean
    
    UNION ALL
    
    SELECT 
        'Device Category' as dimension,
        device_category as dimension_value,
        COUNT(*) as total_visits,
        SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
        ROUND((SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as bounce_rate_pct
    FROM clean.traffic_data
    GROUP BY device_category
    
    UNION ALL
    
    SELECT 
        'Page Category' as dimension,
        page_category as dimension_value,
        COUNT(*) as total_visits,
        SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) as bounce_visits,
        ROUND((SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as bounce_rate_pct
    FROM clean.traffic_data
    GROUP BY page_category
    
    ORDER BY dimension, bounce_rate_pct
);

-- Step 7: Create summary views for Power BI
CREATE VIEW analytics.vw_traffic_kpis AS
SELECT 
    COUNT(*) as total_visits,
    COUNT(DISTINCT user_id) as unique_visitors,
    COUNT(DISTINCT session_id) as unique_sessions,
    ROUND(AVG(session_duration), 2) as avg_session_duration,
    ROUND((SUM(CASE WHEN is_bounce = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as overall_bounce_rate,
    ROUND((SUM(page_views) * 1.0 / COUNT(DISTINCT session_id)), 2) as avg_pages_per_session,
    COUNT(*) / 13 as avg_daily_visits -- 13 days in analysis period
FROM clean.traffic_data;

-- Create indexes for better performance
CREATE INDEX idx_daily_traffic_date ON analytics.daily_traffic_analysis(traffic_date);
CREATE INDEX idx_hourly_patterns_hour ON analytics.hourly_traffic_patterns(visit_hour);
CREATE INDEX idx_weekly_trends_week ON analytics.weekly_trends(visit_week);

-- Display key results
SELECT 'Overall Traffic KPIs' as report_section;
SELECT * FROM analytics.vw_traffic_kpis;

SELECT 'Traffic Source Performance' as report_section;
SELECT * FROM analytics.traffic_source_analysis ORDER BY quality_score DESC;

SELECT 'Page Performance Analysis' as report_section;
SELECT * FROM analytics.page_performance_analysis ORDER BY performance_score DESC;

SELECT 'Peak Hours Analysis' as report_section;
SELECT visit_hour, total_visits, unique_visitors, hour_category, pct_of_daily_traffic
FROM analytics.hourly_traffic_patterns 
ORDER BY total_visits DESC;