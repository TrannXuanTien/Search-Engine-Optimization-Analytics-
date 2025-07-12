-- Step 1: Create staging tables for raw data import
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS clean;

-- Raw traffic data from Excel import
CREATE TABLE staging.raw_traffic_data (
    session_id VARCHAR(255),
    user_id VARCHAR(255),
    page_url VARCHAR(500),
    page_title VARCHAR(255),
    visit_datetime DATETIME,
    session_duration INT,
    page_views INT,
    bounce_flag BIT,
    traffic_source VARCHAR(100),
    device_type VARCHAR(50),
    browser VARCHAR(50),
    location VARCHAR(100)
);

-- Raw user registration data
CREATE TABLE staging.raw_user_registrations (
    registration_id VARCHAR(255),
    user_id VARCHAR(255),
    email VARCHAR(255),
    registration_date DATE,
    last_login_date DATE,
    account_status VARCHAR(50),
    subscription_type VARCHAR(50)
);

-- Raw content interaction data
CREATE TABLE staging.raw_content_interactions (
    interaction_id VARCHAR(255),
    user_id VARCHAR(255),
    content_id VARCHAR(255),
    content_type VARCHAR(100),
    content_category VARCHAR(100),
    interaction_type VARCHAR(50),
    interaction_datetime DATETIME,
    time_spent_seconds INT,
    completion_rate DECIMAL(5,2)
);

-- Step 2: Data cleaning and standardization

-- Clean traffic data
CREATE TABLE clean.traffic_data AS (
    SELECT 
        session_id,
        COALESCE(user_id, 'anonymous_' + session_id) AS user_id,
        
        -- Clean and categorize page URLs
        CASE 
            WHEN page_url LIKE '%/blog/%' THEN 'Blog'
            WHEN page_url LIKE '%/course/%' OR page_url LIKE '%/lesson/%' THEN 'Online Learning'
            WHEN page_url LIKE '%/register%' OR page_url LIKE '%/signup%' THEN 'Registration'
            WHEN page_url LIKE '%/account%' OR page_url LIKE '%/profile%' THEN 'Account Info'
            WHEN page_url LIKE '%/survey%' OR page_url LIKE '%/form%' THEN 'Survey/Form'
            WHEN page_url = '/' OR page_url LIKE '%/home%' THEN 'Homepage'
            ELSE 'Other'
        END AS page_category,
        
        page_title,
        visit_datetime,
        
        -- Handle null session durations
        COALESCE(session_duration, 0) AS session_duration,
        COALESCE(page_views, 1) AS page_views,
        COALESCE(bounce_flag, 0) AS is_bounce,
        
        -- Standardize traffic sources
        CASE 
            WHEN traffic_source = '' OR traffic_source IS NULL THEN 'Direct'
            WHEN traffic_source LIKE '%google%' THEN 'Search Engine'
            WHEN traffic_source LIKE '%facebook%' OR traffic_source LIKE '%social%' THEN 'Social Media'
            WHEN traffic_source LIKE '%email%' THEN 'Email Campaign'
            ELSE 'Referral'
        END AS traffic_source_clean,
        
        -- Standardize device types
        CASE 
            WHEN device_type LIKE '%mobile%' OR device_type LIKE '%phone%' THEN 'Mobile'
            WHEN device_type LIKE '%tablet%' THEN 'Tablet'
            WHEN device_type LIKE '%desktop%' OR device_type LIKE '%computer%' THEN 'Desktop'
            ELSE 'Other'
        END AS device_category,
        
        browser,
        location,
        
        -- Extract time components for analysis
        EXTRACT(HOUR FROM visit_datetime) AS visit_hour,
        EXTRACT(DAY FROM visit_datetime) AS visit_day,
        EXTRACT(WEEK FROM visit_datetime) AS visit_week,
        DATENAME(WEEKDAY, visit_datetime) AS weekday_name
        
    FROM staging.raw_traffic_data
    WHERE visit_datetime >= '2021-08-12'  -- Start of analysis period
      AND visit_datetime <= '2021-08-24'  -- End of analysis period
      AND page_url IS NOT NULL
);

-- Clean user registration data
CREATE TABLE clean.user_registrations AS (
    SELECT 
        registration_id,
        user_id,
        LOWER(TRIM(email)) AS email_clean,
        
        -- Categorize users based on email domain
        CASE 
            WHEN email LIKE '%@gmail.com' 
              OR email LIKE '%@yahoo.com' 
              OR email LIKE '%@hotmail.com' THEN 'Personal'
            WHEN email LIKE '%@edu%' 
              OR email LIKE '%university%' 
              OR email LIKE '%college%'
              OR email LIKE '%@student.%' THEN 'Student'
            WHEN email LIKE '%@outlook.com'
              OR email LIKE '%@company.com'
              OR email LIKE '%@corp.%' THEN 'Corporate'
            ELSE 'Other'
        END AS user_category,
        
        registration_date,
        last_login_date,
        
        -- Calculate user engagement metrics
        DATEDIFF(DAY, registration_date, COALESCE(last_login_date, '2021-08-24')) AS days_active,
        
        CASE 
            WHEN account_status = 'active' THEN 1 
            ELSE 0 
        END AS is_active,
        
        COALESCE(subscription_type, 'Free') AS subscription_type_clean
        
    FROM staging.raw_user_registrations
    WHERE email IS NOT NULL
      AND email LIKE '%@%'  -- Basic email validation
      AND registration_date >= '2021-08-01'
);

-- Clean content interaction data
CREATE TABLE clean.content_interactions AS (
    SELECT 
        interaction_id,
        user_id,
        content_id,
        
        -- Standardize content types
        CASE 
            WHEN content_type LIKE '%blog%' THEN 'Blog'
            WHEN content_type LIKE '%course%' OR content_type LIKE '%lesson%' THEN 'Course'
            WHEN content_type LIKE '%video%' THEN 'Video'
            WHEN content_type LIKE '%survey%' OR content_type LIKE '%form%' THEN 'Survey'
            ELSE 'Other'
        END AS content_type_clean,
        
        -- Categorize content by subject
        CASE 
            WHEN content_category LIKE '%data%' 
              OR content_category LIKE '%excel%' 
              OR content_category LIKE '%sql%' 
              OR content_category LIKE '%powerbi%' THEN 'Data Skills'
            WHEN content_category LIKE '%young%talent%' 
              OR content_category LIKE '%career%' THEN 'Young Talent Program'
            WHEN content_category LIKE '%soft%skill%' 
              OR content_category LIKE '%communication%' THEN 'Soft Skills'
            WHEN content_category LIKE '%technical%' 
              OR content_category LIKE '%programming%' THEN 'Technical Skills'
            ELSE 'Other'
        END AS content_category_clean,
        
        interaction_type,
        interaction_datetime,
        
        -- Handle time spent outliers
        CASE 
            WHEN time_spent_seconds > 3600 THEN 3600  -- Cap at 1 hour
            WHEN time_spent_seconds < 5 THEN 5        -- Minimum 5 seconds
            ELSE time_spent_seconds 
        END AS time_spent_clean,
        
        -- Validate completion rates
        CASE 
            WHEN completion_rate > 100 THEN 100
            WHEN completion_rate < 0 THEN 0
            ELSE COALESCE(completion_rate, 0)
        END AS completion_rate_clean,
        
        -- Extract time components
        EXTRACT(HOUR FROM interaction_datetime) AS interaction_hour,
        EXTRACT(DAY FROM interaction_datetime) AS interaction_day
        
    FROM staging.raw_content_interactions
    WHERE interaction_datetime >= '2021-08-12'
      AND interaction_datetime <= '2021-08-24'
      AND user_id IS NOT NULL
);

-- Step 3: Data quality checks
CREATE TABLE clean.data_quality_report AS (
    SELECT 
        'Traffic Data' as table_name,
        COUNT(*) as total_records,
        COUNT(CASE WHEN user_id IS NULL THEN 1 END) as null_user_ids,
        COUNT(CASE WHEN session_duration = 0 THEN 1 END) as zero_duration_sessions,
        MIN(visit_datetime) as earliest_date,
        MAX(visit_datetime) as latest_date
    FROM clean.traffic_data
    
    UNION ALL
    
    SELECT 
        'User Registrations' as table_name,
        COUNT(*) as total_records,
        COUNT(CASE WHEN email_clean IS NULL THEN 1 END) as null_emails,
        COUNT(CASE WHEN user_category = 'Other' THEN 1 END) as uncategorized_users,
        MIN(registration_date) as earliest_date,
        MAX(registration_date) as latest_date
    FROM clean.user_registrations
    
    UNION ALL
    
    SELECT 
        'Content Interactions' as table_name,
        COUNT(*) as total_records,
        COUNT(CASE WHEN content_category_clean = 'Other' THEN 1 END) as uncategorized_content,
        COUNT(CASE WHEN time_spent_clean = 5 THEN 1 END) as minimum_time_records,
        MIN(interaction_datetime) as earliest_date,
        MAX(interaction_datetime) as latest_date
    FROM clean.content_interactions
);

-- Step 4: Create indexes for better performance
CREATE INDEX idx_traffic_user_id ON clean.traffic_data(user_id);
CREATE INDEX idx_traffic_datetime ON clean.traffic_data(visit_datetime);
CREATE INDEX idx_traffic_category ON clean.traffic_data(page_category);

CREATE INDEX idx_users_category ON clean.user_registrations(user_category);
CREATE INDEX idx_users_registration_date ON clean.user_registrations(registration_date);

CREATE INDEX idx_content_user_id ON clean.content_interactions(user_id);
CREATE INDEX idx_content_category ON clean.content_interactions(content_category_clean);
CREATE INDEX idx_content_datetime ON clean.content_interactions(interaction_datetime);

-- Step 5: Create summary statistics for validation
CREATE VIEW clean.vw_data_summary AS
SELECT 
    'Overall Traffic Stats' as metric_category,
    'Total Visits' as metric_name,
    CAST(COUNT(*) AS VARCHAR) as metric_value
FROM clean.traffic_data

UNION ALL

SELECT 
    'Overall Traffic Stats' as metric_category,
    'Unique Users' as metric_name,
    CAST(COUNT(DISTINCT user_id) AS VARCHAR) as metric_value
FROM clean.traffic_data

UNION ALL

SELECT 
    'Overall Traffic Stats' as metric_category,
    'Average Session Duration (minutes)' as metric_name,
    CAST(ROUND(AVG(session_duration) / 60.0, 2) AS VARCHAR) as metric_value
FROM clean.traffic_data
WHERE session_duration > 0

UNION ALL

SELECT 
    'User Registration Stats' as metric_category,
    'Total Registrations' as metric_name,
    CAST(COUNT(*) AS VARCHAR) as metric_value
FROM clean.user_registrations

UNION ALL

SELECT 
    'Content Engagement Stats' as metric_category,
    'Total Content Interactions' as metric_name,
    CAST(COUNT(*) AS VARCHAR) as metric_value
FROM clean.content_interactions;

-- Display final summary
SELECT * FROM clean.data_quality_report;
SELECT * FROM clean.vw_data_summary ORDER BY metric_category, metric_name;