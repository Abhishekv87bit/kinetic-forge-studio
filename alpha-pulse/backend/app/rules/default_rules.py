DEFAULT_RULES = [
    {
        "name": "Debt Reduction + Margin Expansion",
        "description": (
            "Check if total debt decreased for 3+ consecutive quarters "
            "while gross or operating margin expanded."
        ),
        "rule_prompt": (
            "Evaluate whether this company's total debt has decreased for 3+ "
            "consecutive quarters while gross profit margin OR operating margin "
            "has expanded. Use the quarterly financial data provided.\n"
            "Output: {passed: bool, evidence: str, quarters_examined: list}"
        ),
        "asset_class": "equity",
        "weight": 0.8,
    },
    {
        "name": "Insider Selling Red Flag",
        "description": (
            "Detect significant insider selling — executives/directors selling "
            "more than 10% of holdings in the past 90 days."
        ),
        "rule_prompt": (
            "Analyze insider transaction data. Flag if any C-suite executive or "
            "board member has sold more than 10% of their holdings in the past "
            "90 days. Consider the context — is this a planned 10b5-1 sale or "
            "discretionary?\n"
            "Output: {passed: bool, flagged_insiders: list, severity: str}"
        ),
        "asset_class": "equity",
        "weight": 0.9,
    },
    {
        "name": "Revenue Growth Trend",
        "description": (
            "Check for positive year-over-year revenue growth for at least "
            "2 of the last 4 quarters."
        ),
        "rule_prompt": (
            "Evaluate whether this company has shown positive year-over-year "
            "revenue growth in at least 2 of the last 4 quarters. Calculate "
            "the growth rates and identify the trend direction.\n"
            "Output: {passed: bool, growth_rates: list, trend: str}"
        ),
        "asset_class": "equity",
        "weight": 0.7,
    },
    {
        "name": "Crypto Social Momentum",
        "description": (
            "Assess social media momentum for crypto assets — trending mentions, "
            "sentiment shift, community growth."
        ),
        "rule_prompt": (
            "Analyze the social media data for this cryptocurrency. Evaluate: "
            "1) Are mentions trending up? 2) Is sentiment shifting positive? "
            "3) Is community engagement growing? Score each factor.\n"
            "Output: {passed: bool, mention_trend: str, sentiment_shift: str, "
            "engagement_score: float}"
        ),
        "asset_class": "crypto",
        "weight": 0.6,
    },
    {
        "name": "Macro Headwind Detector",
        "description": (
            "Detect macro headwinds — rising rates, inverted yield curve, "
            "elevated inflation, rising unemployment."
        ),
        "rule_prompt": (
            "Evaluate the current macro environment. Check: "
            "1) Are interest rates rising? 2) Is the yield curve inverted? "
            "3) Is CPI above 4%? 4) Is unemployment trending up? "
            "If 2+ factors are negative, flag as headwind.\n"
            "Output: {passed: bool, factors: list, headwind_severity: str}"
        ),
        "asset_class": None,
        "weight": 0.5,
    },
    {
        "name": "Lifecycle Stage Alignment",
        "description": (
            "Favor companies in maturity or growth lifecycle stages. "
            "Penalize companies in decline or introduction stages."
        ),
        "rule_prompt": (
            "Evaluate the company's lifecycle stage based on cash flow patterns. "
            "Maturity (positive operating, negative investing, negative financing) is strongest. "
            "Growth (positive operating, negative investing, positive financing) is good. "
            "Decline or introduction stages are red flags.\n"
            "Output: {passed: bool, lifecycle_stage: str, reasoning: str}"
        ),
        "asset_class": "equity",
        "weight": 0.7,
    },
    {
        "name": "Insider Conviction Signal",
        "description": (
            "Cluster insider buying (3+ executives purchasing within 14 days) "
            "is a strong buy indicator. Heavy insider selling is a warning."
        ),
        "rule_prompt": (
            "Analyze insider trading patterns. Look for cluster buying "
            "(multiple insiders purchasing close together in time). "
            "Weight purchases more heavily than sales (insiders sell for many reasons, "
            "but buy for only one). Score based on net conviction.\n"
            "Output: {passed: bool, net_direction: str, cluster_detected: bool}"
        ),
        "asset_class": "equity",
        "weight": 0.8,
    },
    {
        "name": "Linguistic Red Flag Detector",
        "description": (
            "Worsening 10-K readability combined with positive management tone "
            "suggests obfuscation. Management hiding bad news in complex language."
        ),
        "rule_prompt": (
            "Check for linguistic red flags: Is 10-K readability worsening "
            "(higher Fog index vs prior year)? Is management tone overly positive "
            "relative to actual results? The combination of complex language + "
            "cheerful tone is the strongest deception signal.\n"
            "Output: {passed: bool, readability_trend: str, tone_mismatch: bool}"
        ),
        "asset_class": "equity",
        "weight": 0.6,
    },
]
