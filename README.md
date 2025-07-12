# Website Traffic Analytics Report

A comprehensive data analytics project for analyzing website traffic patterns, user behavior, and content engagement metrics using SQL and data visualization tools.

## Project Overview

This project analyzes website traffic data from UNIACE VIỆT NAM's educational platform during August 2021. The analysis provides insights into user engagement patterns, content performance, traffic sources, and demographic behavior to inform strategic decision-making.

## Key Metrics Analyzed

- **Total Traffic**: 39,031 visits over 13 days (Aug 12-24, 2021)
- **User Segmentation**: 63.22% unregistered users, 36.68% registered members
- **Conversion Rate**: 16.75% from registration page visits to completed registrations
- **Traffic Sources**: Direct (66.96%), Search Engines (27.2%), Social Media (5.85%)

## Data Sources

The project analyzes website analytics data from three CSV files containing user activity tracking:

1. **Uniace.csv**: 50,919 records (Primary dataset - January 2021 onwards)
2. **Uniace_2.csv**: 23,376 records (August 2021 focused data)
3. **Uniace_3.csv**: 19,766 records (Late August 2021 data)

**Total Records**: 94,061 user interactions across all datasets

## Repository Structure

```
├── data_cleaning.sql          # Data cleaning and standardization scripts
├── traffic_analysis.sql       # Core traffic analysis and KPI calculations
├── user_segmentation.sql      # User behavior and demographic analysis
├── Uniace.csv                 # Primary dataset (50,919 records)
├── Uniace_2.csv              # August 2021 dataset (23,376 records)
├── Uniace_3.csv              # Late August 2021 dataset (19,766 records)
├── README.md                  # This file
└── reports/
    └── Website_Traffic_Report.pdf  # Executive summary and visualizations
```

## SQL Scripts Description

### 1. data_cleaning.sql
- Creates staging and clean data schemas
- Standardizes traffic sources, device types, and page categories
- Implements data quality checks and validation
- Handles outliers and missing values
- Creates indexes for performance optimization

### 2. traffic_analysis.sql
- Daily and hourly traffic pattern analysis
- Traffic source performance evaluation
- Page performance and bounce rate analysis
- Weekly trend identification
- Quality scoring for traffic channels

### 3. user_segmentation.sql
- User categorization by email domain (Student, Corporate, Personal)
- Engagement metrics calculation
- Behavioral pattern analysis
- Content preference identification

## Key Findings

### Traffic Patterns
- **Peak Hours**: 9:00 AM, 12:00 PM, 3:00 PM, and 9:00-10:00 PM
- **Bounce Rate**: Low at 3.44%, indicating high content relevance
- **User Behavior**: Students prefer lunch-time learning, professionals learn evenings

### Content Performance
- **Blog Content**: Data skills content drives 50% of blog traffic
- **Course Enrollment**: Data courses (43.66%) and soft skills popular
- **Young Talent Program**: Generates 28% of blog engagement

### User Demographics
- **Registration Distribution**: 
  - Personal emails: 1,910 accounts (87.1%)
  - Corporate emails: 125 accounts (5.7%)
  - Student emails: 124 accounts (5.7%)

## Database Schema

### Staging Tables (for CSV import)
- `staging.raw_marketing_analytics` - Primary Uniace.csv data (50,919 records)
- `staging.raw_marketing_analytics_2` - Uniace_2.csv data (23,376 records)  
- `staging.raw_marketing_analytics_3` - Uniace_3.csv data (19,766 records)

### Clean Data Tables
- `clean.traffic_data` - Processed website visit records from 'page' type activities
- `clean.user_registrations` - User identification and email data
- `clean.content_interactions` - Email engagement and form submission metrics

### Analytics Tables
- `analytics.daily_traffic_analysis` - Daily aggregated metrics
- `analytics.hourly_traffic_patterns` - Time-based traffic distribution
- `analytics.traffic_source_analysis` - Channel performance metrics
- `analytics.page_performance_analysis` - Content effectiveness scores
- `analytics.email_engagement_analysis` - Email campaign performance

### Common Fields Across All Files
- **Email**: User email addresses (30-42% completion rate)
- **Type**: Activity type (page, templates_open, identify, list_addition, templates_click, form, templates_unsubscribe)
- **Name**: Page/content name
- **Title**: Page title
- **MA URL**: Full URL of the visited page
- **MA Referrer**: Traffic source referrer URL
- **ma_path**: Page path (e.g., "/vyt", "/mda")
- **IP Address**: User IP address
- **Date**: Activity timestamp
- **Message Id**: Email message identifier (for email interactions)
- **Template Id**: Email template identifier
- **List Id**: Mailing list identifier
- **Form Id**: Form submission identifier
- **Campaign Id**: Marketing campaign identifier
- **Campaign Name**: Marketing campaign name
- **Scenario Id**: Marketing automation scenario
- **URL**: Additional URL field
- **Link**: Link click tracking
- **Tag**: Content/campaign tags

### File-Specific Details
- **Uniace.csv**: Contains `cuid` field for customer unique identification
- **Uniace_2.csv & Uniace_3.csv**: Missing `cuid` field but have detailed timestamp data

### Activity Types Tracked
1. **page**: Website page visits
2. **templates_open**: Email template opens
3. **identify**: User identification events
4. **list_addition**: Mailing list subscriptions
5. **templates_click**: Email link clicks
6. **form**: Form submissions
7. **templates_unsubscribe**: Email unsubscriptions

## Setup Instructions

### Prerequisites
- SQL Server or compatible database system
- Power BI or similar visualization tool (optional)
- Excel for data import capabilities

### Installation
1. Clone this repository
2. Execute scripts in the following order:
   ```sql
   -- 1. Set up schemas and clean data
   SOURCE data_cleaning.sql;
   
   -- 2. Run traffic analysis
   SOURCE traffic_analysis.sql;
   
   -- 3. Perform user segmentation
   SOURCE user_segmentation.sql;
   ```

3. Import CSV data into staging tables:
   ```sql
   -- Import the three CSV files into staging tables
   BULK INSERT staging.raw_marketing_analytics FROM 'Uniace.csv';
   BULK INSERT staging.raw_marketing_analytics_2 FROM 'Uniace_2.csv';
   BULK INSERT staging.raw_marketing_analytics_3 FROM 'Uniace_3.csv';
   ```

### CSV Data Import Format
The three CSV files should be imported with the following structure:
- **Headers**: Email, Type, Name, Title, MA URL, MA Referrer, ma_path, IP Address, Date, etc.
- **Encoding**: UTF-8 (Uniace_2.csv, Uniace_3.csv) or CP1252 (Uniace.csv)
- **Date Formats**: 
  - Uniace.csv & Uniace_2.csv: "YYYY/MM/DD HH:MM:SS"
  - Uniace_3.csv: "YY-MM-DD HH:MM"

## Key Performance Indicators (KPIs)

### Traffic Metrics
- Daily visit volume and growth rates
- Unique visitor counts
- Session duration averages
- Pages per session
- Bounce rate by traffic source

### Engagement Metrics
- Content completion rates
- Time spent on page
- User return frequency
- Conversion funnel performance

### Business Metrics
- Registration conversion rates
- Course enrollment by category
- User segment behavior patterns
- Content ROI indicators

## Recommendations Based on Analysis

### Content Strategy
1. **Expand Data Skills Content**: 50% of users seek data-related content
2. **Develop Technical Skills Courses**: Only 2.76% enrollment suggests improvement opportunity
3. **Leverage Young Talent Program**: High interest (28% of blog traffic) indicates growth potential

### User Experience Optimization
1. **Peak Hour Content Delivery**: Optimize for 9 AM, 12 PM, 3 PM, and 9-10 PM traffic
2. **Mobile Optimization**: Significant mobile traffic requires responsive design
3. **User-Specific Journeys**: Different content strategies for students vs. professionals

### Marketing Focus
1. **Direct Traffic Optimization**: 66.96% direct traffic suggests strong brand recognition
2. **Social Media Expansion**: Current 5.85% share has growth potential
3. **SEO Investment**: Search engine traffic at 27.2% could be increased

## Data Quality Measures

- **Validation Rules**: Email format checking, date range validation
- **Outlier Handling**: Session duration capped at 1 hour, minimum 5 seconds
- **Missing Data**: Anonymous user IDs generated for null values
- **Standardization**: Consistent categorization across all data sources

## Future Enhancements

1. **Real-time Analytics**: Implement streaming data processing
2. **Predictive Modeling**: Forecast traffic patterns and user behavior
3. **A/B Testing Framework**: Systematic content and UX testing
4. **Advanced Segmentation**: Machine learning-based user clustering
5. **ROI Analysis**: Revenue attribution to traffic sources and content

## Acknowledgments
- This project purpose is only for learning, it does not represent any company private data. 
- SQL optimization and performance tuning.
- Power BI dashboard development and visualization design

---

*Last Updated: July 2025*
*Project Version: 1.0*
