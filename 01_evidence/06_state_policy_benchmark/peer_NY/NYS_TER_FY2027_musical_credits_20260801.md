# NYS Annual Report on Tax Expenditures — musical/theatrical credits (extract)

**Sources**
- FY2027 edition (2026 report): https://www.tax.ny.gov/data/stats/ter/fiscal-year27/cross-article-tax-credits.htm
- FY2026 edition (2025 report): https://www.tax.ny.gov/data/stats/ter/fiscal-year26/cross-article-tax-credits.htm

**Accessed:** 2026-08-01
**Publisher:** New York State Department of Taxation and Finance
**Extraction method:** HTML saved via curl, tables parsed programmatically (not read off a rendered page)

These are **amounts actually claimed on tax returns**, not amounts allocated by ESD.
See `_notes_NY.md` for the distinction between authorized, allocated, and claimed.

---

## FY2027 edition — Table 8: "2026 New York State cross-article tax credits estimates (in millions of dollars)"

Column headers: `Tax item | 2018 | 2019 | 2020 | 2021 | 2022 | 2023(fn1) | Forecast 2026`

### Item 29. Musical and theatrical production credit (upstate, § 24-a)
```
Personal income tax      |  *  |  *  | 0.0 | 0.0 |  *  |  *  | 2.0
Corporate franchise tax  | 0.8 | 2.3 | 0.0 | 1.6 | 0.7 |     | 6.0
Total                    | 0.8 | 2.3 | 0.0 | 1.6 | 0.7 |     | 8.0
```

### Item 39. New York City musical and theatrical production tax credit (§ 24-c)
```
Personal income tax      | --  | --  | --  | 0.0 |  8.9 | 2.7 |  10.0
Corporate franchise tax  | --  | --  | --  |14.5 | 76.5 |     |  90.0
Total                    |     |     |     |14.5 | 85.4 |     | 100.0
```

**Legend (verbatim from source):**
- `*` = Less than $0.1 million
- `--` = The tax expenditure was not applicable for these years

**Footnote 1 (applies to the 2023 column), verbatim opening:**
> "Data for non-personal income tax items are not yet available."

So the 2023 figure of $2.7M is **personal income tax only** and is not a year total.

---

## FY2026 edition — Table 8: "2025 New York State cross-article tax credits estimates (in millions of dollars)"

Column headers: `Tax item | 2017 | 2018 | 2019 | 2020 | 2021 | 2022(fn1) | Forecast 2025`

### Item 30. Musical and theatrical production credit (upstate, § 24-a)
```
Personal income tax      | 1.2 |  *  |  *  | 0.0 | 0.0 |  *  | 2.0
Corporate franchise tax  | 0.4 | 0.8 | 2.3 | 0.0 | 1.6 |     | 6.0
Total                    | 1.6 | 0.8 | 2.3 | 0.0 | 1.6 |     | 8.0
```

### Item 40. New York City musical and theatrical production tax credit (§ 24-c)
```
Personal income tax      | --  | --  | --  | --  | 0.0 |  8.9 | 13.0
Corporate franchise tax  | --  | --  | --  | --  |14.5 |      | 37.0
Total                    |     |     |     |     |14.5 |      | 50.0
```

---

## Year-over-year comparison — what changed between editions

| | FY2026 edition (2025 report) | FY2027 edition (2026 report) |
|---|---|---|
| NYC credit, tax year 2022 | PIT $8.9M; CFT not yet available | **complete: $85.4M** ($8.9M PIT + $76.5M CFT) |
| NYC credit, forward forecast | **$50.0M** (forecast 2025) | **$100.0M** (forecast 2026) |
| Upstate credit, tax year 2022 | not yet available | **$0.7M** |

Two things worth saying in the paper:
1. The state **doubled its own forward forecast** for the NYC credit between consecutive
   editions ($50.0M → $100.0M).
2. The upstate credit's forecast sits at **$8.0M — exactly its statutory annual cap** —
   while realized claims have never exceeded $2.3M in any observed year. The forecast
   tracks the authorization, not observed behavior.

---

## Credit descriptions (FY2027 edition, verbatim excerpts)

### NYC musical and theatrical production tax credit
- Credit type: **Refundable**
- Effective date: "Effective for tax years beginning on or after January 1, 2021, and before January 1, 2028"
- "Participants may claim a refundable tax credit equal to **25 percent** of qualified production expenditures paid for during the qualified New York City musical and theatrical production's credit period."
- "For tax years beginning or after January 1, 2025, an **additional $100 million** in total credit is available."
- "Starting in 2023, the credit is amended to add **Level 1 and Level 2** qualified New York City production facilities."
- "The amount of the credit cannot exceed **$350,000** per qualified New York City musical and theatrical production in a Level 2 facility or **$3,000,000** per qualified New York City musical and theatrical production in a Level 1 facility."
- Level 2 productions "must have a production budget greater than or equal to $750,000 and incur qualified production [expenditures of at least $750,000]"
- "personal compensation expenses capped at **$200,000 per week**"
- TER citation given as: **Tax Law §§ 210-B(40), 606(xxx)** — note this **conflicts** with the
  cross-references in the § 24-c statute text itself (§ 210-B(57), § 606(mmm)). Verify before citing.

### Musical and theatrical production credit (upstate)
- Credit type: **Refundable**
- Citation: **Tax Law §§ 24-A, 210-B(47), 606(u)**
- Effective: "tax years beginning on or after January 1, 2015, and before January 1, 2026"
- "The credit equals **25%** of eligible production costs, with an **annual cap of $8 million**,
  administered by Empire State Development."
