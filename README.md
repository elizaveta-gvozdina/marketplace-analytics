# E-commerce Analytics Case Study
![dashboard_page_1_revenue](./dashboard/dashboard_page_1_revenue.png)
## Business Context
Fecom Inc. is a growing e-commerce marketplace connecting sellers with a broad customer base. Daily orders, shipments, and customer interactions generate substantial data, but it is stored across multiple tables without a unified view.

❌As a result:  
- Revenue, product, and seller performance are hard to monitor  
- Customer behavior and retention patterns are difficult to analyze  
- KPIs are inconsistent, making benchmarking challenging
- Delivery and fulfillment bottlenecks are not easily detected

This project consolidates these datasets into a single analytical dashboard, providing a year-to-date view benchmarked against the previous year, enabling actionable insights for revenue, product assortment, seller management, customer engagement, and operational efficiency.

Additionally, this project incorporates RFM-based customer segmentation with K-Means clustering to identify high-value, loyal, and at-risk customers, uncover retention opportunities, and support targeted, data-driven campaigns.

## 🚀 Interactive Dashboard
Click to open the live Power BI dashboard → [View the Dashboard →](https://app.powerbi.com/view?r=eyJrIjoiN2Q1MTNlOTYtNjE3YS00YWNjLWJjZWYtMTcyZDRmMTE0MTgzIiwidCI6IjFlYWQ2ZmY5LTIxOTItNGE2OC05ODQ2LTNiYTUwNGQ4MGViYiJ9&pageName=e2f321812e80b51cafb2)
 Detailed page-by-page descriptions and screenshots are provided [below](#dashboard-details).

## 🛠️Project Stack
PostgreSQL | SQL | Python (Pandas, NumPy, scikit-learn) | Jupyter Notebook | Power BI (DAX) | RFM Analysis

## Table of Contents
- [Business Objectives](#business-objectives)<br>
- [Methodology](#methodology)<br>
- [Data Model](#data-model)<br>
- [Dashboard Details](#dashboard-details)<br>
- [Insights](#insights)<br>
- [Next Steps](#next-steps)<br>
- [How to Use](#how-to-use)<br>
- [Customer Segmentation with RFM and K-Means](#customer-segmentation-with-rfm-and-k-means)<br>
- [Dataset](#dataset)<br>
- [Limitations](#limitations)<br>
- [Contact](#contact)<br> 

## Business Objectives
- Provide a clear, consolidated view of year-to-date performance, highlighting trends in revenue, customer behavior, and operational metrics  
- Monitor KPIs across revenue, retention, product assortment, seller efficiency, and delivery operations  
- Identify top-performing and underperforming products and sellers to guide assortment and partner management  
- Detect bottlenecks in delivery and fulfillment to improve efficiency and customer satisfaction  
- Deliver actionable insights that inform strategic initiatives with measurable impact

## Methodology
### ETL / Data Cleaning
The raw data from the source datasets is ingested and cleaned using the following scripts:

- [Data Preprocessing Notebook](./elt_scripts/data_preprocessing.ipynb) — checks for missing or duplicate values and corrects formatting issues.
- [ELT Pipeline](./elt_scripts/ELT_pipeline.py) — automates data ingestion, normalization, and storage in PostgreSQL.

## Data Model
The project uses different data models across layers to balance storage efficiency and analytical usability:

1. **PostgreSQL (Data Storage Layer)**  
   Source data is normalized up to the Third Normal Form (3NF) in a snowflake-style schema. This reduces redundancy, ensures data integrity, and supports efficient storage.

2. **Power BI (Analytics / Semantic Layer)**  
     A star schema with multiple fact tables at different grains is implemented to simplify relationships, filtering, and measure calculations. Power BI uses the VertiPaq engine, which stores data in a highly compressed, columnar format. This makes star schemas with clear fact-dimension relationships extremely fast for aggregations and slicers.

The Entity-Relationship Diagram (ERD) of the PostgreSQL database can be viewed below:  
→ [PostgreSQL ERD](./ERD/ERD_normalized.png)  

The star-schema data model implemented in Power BI is illustrated here:  
→ [Power BI Star Schema](./ERD/powerbi_model.png)

This setup optimizes data storage in PostgreSQL while keeping analytical queries and reporting in Power BI clear, performant, and easy to maintain.

## Customer Segmentation with RFM and K-Means
→ [See detailed analysis here](./rfm_clustering_analysis/RFM_segmentation_with_KMeans.ipynb)

This is part of the Fecom Inc. analytics project. Customers are segmented using RFM (Recency, Frequency, Monetary) metrics and K-Means clustering to identify patterns in purchasing behavior and support targeted marketing and retention strategies.

→ [See segment-level business recommendations here](./rfm_clustering_analysis/customer_segment_recommendations_report.pdf)

**Key Results:**
- Customers grouped into meaningful segments based on recency, frequency, and spending, producing a clear, stable, and business-actionable customer segmentation framework.
- Six distinct customer segments identified: Recent Low Spenders, Recent High Spenders, Inactive Low Spenders, Inactive High Spenders, Loyal High Spenders, and VIP Spenders, enabling differentiated retention and monetization strategies.
- **High churn risk quantified**: ~97% of customers made only one purchase, confirming low retention as a core business challenge and validating the need for lifecycle-based marketing strategies
- **Robust clustering achieved**: 5-cluster solution validated via Elbow Method and Silhouette Score; cluster stability confirmed with a mean Adjusted Rand Index (ARI) of 0.97 across multiple runs.
- **Outlier handling improved model quality**: Top 0.5% spenders isolated as VIPs to prevent distortion of K-Means centroids and improve interpretability.
- **Production-ready output delivered**: Clean customer-level segmentation exported to CSV, with clear business-ready fields and structure suitable for direct integration into Power BI dashboards.
- **Clear business actions defined**: Each segment mapped to prioritized, time-phased actions (quick wins, mid-term, long-term) with measurable KPIs to support churn reduction and CLV growth. 

## Dataset
- Fecom Inc. is a fictional e-commerce marketplace company based in Berlin, Germany. Between 2022 and 2024, it recorded 99 441 orders from 102 727 unique customers and tracked all commercial transactions of 3 095 sellers.
- Source: [Kaggle — Fecom Inc. e-commerce orders](https://www.kaggle.com/datasets/cemeraan/fecom-inc-e-com-marketplace-orders-data-crm/data)
- License: CC BY-NC-SA 4.0
- Collection Methodology: Random Sampling + Market and Company Research Report Results about e-Com[Specific confidential company]


## Limitations
- Temporal coverage is limited to 2022–2024, preventing reliable estimation of long-term trends and seasonality.
- Returns and refunds data is not available, preventing net revenue and return rate analysis.
- Customer acquisition and funnel data is not available, preventing analysis of conversion efficiency and customer acquisition cost (CAC) beyond completed and cancelled orders.
- Planned sales targets or budget benchmarks are not available; performance evaluation relies on year-over-year comparisons.


## Contact
**Project author:**  Elizaveta Gvozdina<br>
**Email:** lisagvozdina@gmail.com<br>
**Phone**: +44 7874 755842<br>

