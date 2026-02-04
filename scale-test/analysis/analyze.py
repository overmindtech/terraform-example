#!/usr/bin/env python3
"""
Quick CLI script for scale test duration analysis.

Usage:
    python analyze.py                    # Use sample data
    python analyze.py --fetch            # Fetch from dashboard API
    python analyze.py --json data.json   # Load from JSON file
"""

import argparse
import json
import os
import sys

import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler

# Sample data from recent runs (50 runs across 4 days)
# Added 'age_hours' to track when each run occurred (0 = most recent)
SAMPLE_DATA = [
    # 11-13h ago (age_hours ~12)
    {"scenario": "kms_orphan_simulation", "duration_seconds": 761, "risk_count": 0, "blast_radius": 677, "edges": 1972, "observations": 246, "age_hours": 11},
    {"scenario": "combined_all", "duration_seconds": 1215, "risk_count": 0, "blast_radius": 803, "edges": 2054, "observations": 304, "age_hours": 12},
    {"scenario": "combined_network", "duration_seconds": 1177, "risk_count": 1, "blast_radius": 749, "edges": 1896, "observations": 281, "age_hours": 12},
    {"scenario": "central_sns_change", "duration_seconds": 594, "risk_count": 1, "blast_radius": 719, "edges": 1989, "observations": 241, "age_hours": 12},
    {"scenario": "vpc_peering_change", "duration_seconds": 814, "risk_count": 0, "blast_radius": 786, "edges": 2108, "observations": 278, "age_hours": 13},
    {"scenario": "lambda_timeout", "duration_seconds": 1445, "risk_count": 0, "blast_radius": 1096, "edges": 12010, "observations": 408, "age_hours": 13},
    {"scenario": "shared_sg_open", "duration_seconds": 1457, "risk_count": 0, "blast_radius": 846, "edges": 1965, "observations": 315, "age_hours": 13},
    # 15-18h ago
    {"scenario": "kms_orphan_simulation", "duration_seconds": 1065, "risk_count": 0, "blast_radius": 619, "edges": 1792, "observations": 227, "age_hours": 15},
    {"scenario": "combined_all", "duration_seconds": 812, "risk_count": 0, "blast_radius": 865, "edges": 1993, "observations": 312, "age_hours": 16},
    {"scenario": "combined_network", "duration_seconds": 1073, "risk_count": 1, "blast_radius": 666, "edges": 1685, "observations": 264, "age_hours": 16},
    {"scenario": "central_sns_change", "duration_seconds": 732, "risk_count": 0, "blast_radius": 816, "edges": 2173, "observations": 286, "age_hours": 17},
    {"scenario": "vpc_peering_change", "duration_seconds": 733, "risk_count": 0, "blast_radius": 622, "edges": 1987, "observations": 209, "age_hours": 17},
    {"scenario": "lambda_timeout", "duration_seconds": 1152, "risk_count": 1, "blast_radius": 956, "edges": 2956, "observations": 351, "age_hours": 17},
    {"scenario": "shared_sg_open", "duration_seconds": 1241, "risk_count": 0, "blast_radius": 895, "edges": 2217, "observations": 302, "age_hours": 18},
    # 1d ago (~24h)
    {"scenario": "kms_orphan_simulation", "duration_seconds": 782, "risk_count": 0, "blast_radius": 768, "edges": 2094, "observations": 276, "age_hours": 24},
    {"scenario": "combined_all", "duration_seconds": 501, "risk_count": 1, "blast_radius": 543, "edges": 1853, "observations": 169, "age_hours": 24},
    {"scenario": "combined_network", "duration_seconds": 845, "risk_count": 1, "blast_radius": 722, "edges": 2107, "observations": 228, "age_hours": 24},
    {"scenario": "central_sns_change", "duration_seconds": 678, "risk_count": 0, "blast_radius": 598, "edges": 1727, "observations": 178, "age_hours": 24},
    {"scenario": "vpc_peering_change", "duration_seconds": 457, "risk_count": 0, "blast_radius": 695, "edges": 2091, "observations": 209, "age_hours": 24},
    {"scenario": "lambda_timeout", "duration_seconds": 776, "risk_count": 0, "blast_radius": 1053, "edges": 7042, "observations": 347, "age_hours": 24},
    {"scenario": "shared_sg_open", "duration_seconds": 636, "risk_count": 2, "blast_radius": 530, "edges": 1617, "observations": 186, "age_hours": 24},
    # 2d ago (~48h)
    {"scenario": "kms_orphan_simulation", "duration_seconds": 438, "risk_count": 1, "blast_radius": 335, "edges": 1037, "observations": 121, "age_hours": 48},
    {"scenario": "combined_all", "duration_seconds": 870, "risk_count": 2, "blast_radius": 881, "edges": 2390, "observations": 298, "age_hours": 48},
    {"scenario": "combined_network", "duration_seconds": 694, "risk_count": 1, "blast_radius": 601, "edges": 1667, "observations": 213, "age_hours": 48},
    {"scenario": "central_sns_change", "duration_seconds": 654, "risk_count": 0, "blast_radius": 657, "edges": 1628, "observations": 206, "age_hours": 48},
    {"scenario": "vpc_peering_change", "duration_seconds": 673, "risk_count": 0, "blast_radius": 947, "edges": 2487, "observations": 318, "age_hours": 48},
    {"scenario": "lambda_timeout", "duration_seconds": 639, "risk_count": 1, "blast_radius": 980, "edges": 3008, "observations": 349, "age_hours": 48},
    {"scenario": "shared_sg_open", "duration_seconds": 573, "risk_count": 0, "blast_radius": 797, "edges": 2040, "observations": 268, "age_hours": 48},
    # 3d ago first batch (~72h)
    {"scenario": "kms_orphan_simulation", "duration_seconds": 538, "risk_count": 1, "blast_radius": 724, "edges": 1726, "observations": 196, "age_hours": 72},
    {"scenario": "combined_all", "duration_seconds": 834, "risk_count": 1, "blast_radius": 717, "edges": 1977, "observations": 226, "age_hours": 72},
    {"scenario": "combined_network", "duration_seconds": 924, "risk_count": 1, "blast_radius": 728, "edges": 1847, "observations": 235, "age_hours": 72},
    {"scenario": "central_sns_change", "duration_seconds": 363, "risk_count": 1, "blast_radius": 429, "edges": 1327, "observations": 128, "age_hours": 72},
    {"scenario": "vpc_peering_change", "duration_seconds": 410, "risk_count": 1, "blast_radius": 595, "edges": 1482, "observations": 174, "age_hours": 72},
    {"scenario": "lambda_timeout", "duration_seconds": 482, "risk_count": 0, "blast_radius": 840, "edges": 2716, "observations": 302, "age_hours": 72},
    {"scenario": "shared_sg_open", "duration_seconds": 684, "risk_count": 2, "blast_radius": 651, "edges": 1857, "observations": 207, "age_hours": 72},
    # 3d ago second batch (~78h)
    {"scenario": "kms_orphan_simulation", "duration_seconds": 487, "risk_count": 0, "blast_radius": 535, "edges": 1446, "observations": 157, "age_hours": 78},
    {"scenario": "combined_all", "duration_seconds": 928, "risk_count": 0, "blast_radius": 837, "edges": 2364, "observations": 284, "age_hours": 78},
    {"scenario": "combined_network", "duration_seconds": 1279, "risk_count": 2, "blast_radius": 973, "edges": 2577, "observations": 318, "age_hours": 78},
    {"scenario": "central_sns_change", "duration_seconds": 707, "risk_count": 0, "blast_radius": 572, "edges": 1603, "observations": 168, "age_hours": 78},
    {"scenario": "vpc_peering_change", "duration_seconds": 484, "risk_count": 0, "blast_radius": 638, "edges": 1853, "observations": 190, "age_hours": 78},
    {"scenario": "lambda_timeout", "duration_seconds": 794, "risk_count": 0, "blast_radius": 897, "edges": 3275, "observations": 337, "age_hours": 78},
    {"scenario": "shared_sg_open", "duration_seconds": 659, "risk_count": 0, "blast_radius": 665, "edges": 1947, "observations": 216, "age_hours": 78},
    # 4d ago (~96h)
    {"scenario": "vpc_peering_change", "duration_seconds": 490, "risk_count": 1, "blast_radius": 676, "edges": 1474, "observations": 186, "age_hours": 96},
    {"scenario": "lambda_timeout", "duration_seconds": 917, "risk_count": 0, "blast_radius": 818, "edges": 2753, "observations": 295, "age_hours": 96},
    {"scenario": "shared_sg_open", "duration_seconds": 1285, "risk_count": 2, "blast_radius": 513, "edges": 1341, "observations": 360, "age_hours": 96},
    {"scenario": "shared_sg_open", "duration_seconds": 865, "risk_count": 1, "blast_radius": 694, "edges": 1454, "observations": 204, "age_hours": 96},
    {"scenario": "central_sns_change", "duration_seconds": 632, "risk_count": 0, "blast_radius": 587, "edges": 1378, "observations": 160, "age_hours": 96},
    {"scenario": "vpc_peering_change", "duration_seconds": 504, "risk_count": 0, "blast_radius": 378, "edges": 935, "observations": 101, "age_hours": 96},
    {"scenario": "lambda_timeout", "duration_seconds": 835, "risk_count": 0, "blast_radius": 1118, "edges": 11954, "observations": 414, "age_hours": 96},
    {"scenario": "shared_sg_open", "duration_seconds": 925, "risk_count": 2, "blast_radius": 508, "edges": 1270, "observations": 154, "age_hours": 96},
]


def fetch_from_api():
    """Fetch run data from dashboard API."""
    import requests
    
    url = os.getenv('SCALE_DASHBOARD_URL', '')
    api_key = os.getenv('SCALE_DASHBOARD_API_KEY', '')
    
    if not url or not api_key:
        print("Error: Set SCALE_DASHBOARD_URL and SCALE_DASHBOARD_API_KEY env vars")
        sys.exit(1)
    
    try:
        response = requests.get(
            f"{url}/api/results",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=30
        )
        response.raise_for_status()
        api_data = response.json()
        
        data = []
        for run in api_data.get('results', api_data):
            data.append({
                "scenario": run.get('scenario'),
                "duration_seconds": run.get('overmindDurationMs', 0) / 1000,
                "risk_count": run.get('riskCount', 0),
                "blast_radius": run.get('blastRadiusNodes', 0),
                "edges": run.get('blastRadiusEdges', 0),
                "observations": run.get('observations', 0),
            })
        return data
    except Exception as e:
        print(f"Error fetching from API: {e}")
        sys.exit(1)


def load_from_json(filepath):
    """Load data from JSON file."""
    with open(filepath) as f:
        return json.load(f)


def analyze_time_series(df):
    """Analyze trends over time."""
    if 'age_hours' not in df.columns:
        print("  No time data available (add age_hours to data)")
        return
    
    print("\n" + "-" * 40)
    print("TIME SERIES ANALYSIS")
    print("-" * 40)
    
    # Overall trend: is duration getting better or worse?
    # Lower age_hours = more recent, so negative correlation = getting slower
    time_corr = df['duration_seconds'].corr(df['age_hours'])
    
    if time_corr > 0.1:
        trend = "IMPROVING"
        trend_desc = "Recent runs are faster than older runs"
    elif time_corr < -0.1:
        trend = "DEGRADING"
        trend_desc = "Recent runs are slower than older runs"
    else:
        trend = "STABLE"
        trend_desc = "No significant change over time"
    
    print(f"\n  Overall trend: {trend}")
    print(f"  {trend_desc}")
    print(f"  (correlation with age: {time_corr:+.3f})")
    
    # Group by time period
    df['period'] = pd.cut(df['age_hours'], 
                          bins=[0, 24, 48, 72, 200],
                          labels=['Last 24h', '1-2 days ago', '2-3 days ago', '3+ days ago'])
    
    print("\n  Average Duration by Time Period:")
    period_stats = df.groupby('period', observed=True).agg({
        'duration_minutes': ['mean', 'std', 'count']
    }).round(1)
    period_stats.columns = ['avg_min', 'std_min', 'count']
    
    # Calculate change from oldest to newest
    periods = ['3+ days ago', '2-3 days ago', '1-2 days ago', 'Last 24h']
    prev_avg = None
    
    for period in periods:
        if period in period_stats.index:
            row = period_stats.loc[period]
            change_str = ""
            if prev_avg is not None:
                change = row['avg_min'] - prev_avg
                pct = (change / prev_avg) * 100
                if abs(pct) > 5:
                    arrow = "↑" if change > 0 else "↓"
                    change_str = f" ({arrow}{abs(pct):.0f}%)"
            prev_avg = row['avg_min']
            print(f"    {period:15s}: {row['avg_min']:5.1f}m ±{row['std_min']:.1f}m (n={int(row['count'])}){change_str}")
    
    # Per-scenario trends
    print("\n  Trend by Scenario (recent vs older):")
    
    scenario_trends = []
    for scenario in df['scenario'].unique():
        sdf = df[df['scenario'] == scenario]
        if len(sdf) >= 3:  # Need at least 3 points
            recent = sdf[sdf['age_hours'] <= 24]['duration_minutes'].mean()
            older = sdf[sdf['age_hours'] > 48]['duration_minutes'].mean()
            
            if pd.notna(recent) and pd.notna(older) and older > 0:
                change_pct = ((recent - older) / older) * 100
                scenario_trends.append({
                    'scenario': scenario,
                    'recent_avg': recent,
                    'older_avg': older,
                    'change_pct': change_pct
                })
    
    if scenario_trends:
        scenario_trends.sort(key=lambda x: x['change_pct'], reverse=True)
        
        for st in scenario_trends:
            if abs(st['change_pct']) > 10:
                arrow = "↑ SLOWER" if st['change_pct'] > 0 else "↓ FASTER"
                print(f"    {st['scenario']:25s}: {arrow} ({st['change_pct']:+.0f}%)")
                print(f"      Recent: {st['recent_avg']:.1f}m → Older: {st['older_avg']:.1f}m")
            else:
                print(f"    {st['scenario']:25s}: stable")


def analyze(data):
    """Run analysis on the data."""
    df = pd.DataFrame(data)
    df['duration_minutes'] = df['duration_seconds'] / 60
    
    print("=" * 60)
    print("SCALE TEST DURATION ANALYSIS")
    print("=" * 60)
    print(f"\nAnalyzing {len(df)} runs across {df['scenario'].nunique()} scenarios\n")
    
    # === Correlation Analysis ===
    print("-" * 40)
    print("CORRELATION WITH DURATION")
    print("-" * 40)
    
    metrics = ['blast_radius', 'edges', 'observations', 'risk_count']
    correlations = {}
    for m in metrics:
        corr = df['duration_seconds'].corr(df[m])
        correlations[m] = corr
        strength = "STRONG" if abs(corr) > 0.7 else "moderate" if abs(corr) > 0.4 else "weak"
        print(f"  {m:20s}: {corr:+.3f} ({strength})")
    
    # === Linear Model ===
    print("\n" + "-" * 40)
    print("DURATION PREDICTION FORMULA")
    print("-" * 40)
    
    features = ['blast_radius', 'edges', 'observations']
    X = df[features]
    y = df['duration_seconds']
    
    model = LinearRegression()
    model.fit(X, y)
    
    print(f"\n  duration_seconds = {model.intercept_:.1f}")
    for feat, coef in zip(features, model.coef_):
        sign = '+' if coef >= 0 else '-'
        print(f"    {sign} {abs(coef):.4f} × {feat}")
    
    r2 = model.score(X, y)
    print(f"\n  R² = {r2:.3f} ({r2*100:.0f}% of variance explained)")
    
    # === Feature Importance ===
    print("\n" + "-" * 40)
    print("FEATURE IMPORTANCE")
    print("-" * 40)
    
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    model_scaled = LinearRegression()
    model_scaled.fit(X_scaled, y)
    
    importance = pd.DataFrame({
        'Feature': features,
        'Importance': np.abs(model_scaled.coef_)
    }).sort_values('Importance', ascending=False)
    
    total = importance['Importance'].sum()
    for _, row in importance.iterrows():
        pct = row['Importance'] / total * 100
        bar = "█" * int(pct / 5)
        print(f"  {row['Feature']:20s}: {pct:5.1f}% {bar}")
    
    # === Outliers ===
    print("\n" + "-" * 40)
    print("OUTLIERS (>30% deviation from expected)")
    print("-" * 40)
    
    df['predicted'] = model.predict(X)
    df['residual_pct'] = (df['duration_seconds'] - df['predicted']) / df['predicted'] * 100
    
    outliers = df[abs(df['residual_pct']) > 30].sort_values('residual_pct', ascending=False)
    
    if len(outliers) > 0:
        print("\n  Slower than expected:")
        for _, row in outliers[outliers['residual_pct'] > 0].iterrows():
            print(f"    {row['scenario']:25s}: {row['duration_minutes']:.1f}m actual vs {row['predicted']/60:.1f}m expected ({row['residual_pct']:+.0f}%)")
        
        print("\n  Faster than expected:")
        for _, row in outliers[outliers['residual_pct'] < 0].iterrows():
            print(f"    {row['scenario']:25s}: {row['duration_minutes']:.1f}m actual vs {row['predicted']/60:.1f}m expected ({row['residual_pct']:+.0f}%)")
    else:
        print("  None (all runs within 30% of expected)")
    
    # === Scenario Summary ===
    print("\n" + "-" * 40)
    print("SCENARIO SUMMARY")
    print("-" * 40)
    
    summary = df.groupby('scenario').agg({
        'duration_minutes': ['mean', 'std'],
        'edges': 'mean',
        'blast_radius': 'mean'
    }).round(1)
    summary.columns = ['avg_min', 'std_min', 'avg_edges', 'avg_nodes']
    summary = summary.sort_values('avg_min', ascending=False)
    
    print(f"\n  {'Scenario':25s} {'Avg Duration':>12s} {'Std Dev':>10s} {'Avg Edges':>12s}")
    print("  " + "-" * 60)
    for name, row in summary.iterrows():
        std = f"±{row['std_min']:.1f}m" if not pd.isna(row['std_min']) else "N/A"
        print(f"  {name:25s} {row['avg_min']:>10.1f}m {std:>10s} {row['avg_edges']:>12,.0f}")
    
    # === Key Insights ===
    print("\n" + "=" * 60)
    print("KEY INSIGHTS")
    print("=" * 60)
    
    top_corr = max(correlations, key=lambda x: abs(correlations[x]))
    print(f"\n1. {top_corr.upper()} is the strongest predictor of duration")
    print(f"   (correlation: {correlations[top_corr]:+.3f})")
    
    if r2 > 0.7:
        print(f"\n2. Duration is {r2*100:.0f}% predictable from blast radius, edges, and observations")
    else:
        print(f"\n2. Only {r2*100:.0f}% of duration variance is explained by metrics")
        print("   Other factors (scenario complexity, API latency) also matter")
    
    slowest = summary.index[0]
    print(f"\n3. Slowest scenario: {slowest} ({summary.loc[slowest, 'avg_min']:.1f}m average)")
    
    print("\n" + "=" * 60)
    
    # Time series analysis
    analyze_time_series(df)
    
    print("\n" + "=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Analyze scale test durations")
    parser.add_argument('--fetch', action='store_true', help="Fetch from dashboard API")
    parser.add_argument('--json', type=str, help="Load from JSON file")
    args = parser.parse_args()
    
    if args.fetch:
        data = fetch_from_api()
    elif args.json:
        data = load_from_json(args.json)
    else:
        print("Using sample data (use --fetch or --json for real data)\n")
        data = SAMPLE_DATA
    
    analyze(data)


if __name__ == "__main__":
    main()
