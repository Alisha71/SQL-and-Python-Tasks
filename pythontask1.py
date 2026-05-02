import pandas as pd
import numpy as np
from pydantic import BaseModel, ValidationError, field_validator
from typing import Optional

# -- References --
# https://pandantic-rtd.readthedocs.io/en/latest/usage.html#using-the-validator
# https://pandantic-rtd.readthedocs.io/en/latest/
# https://pydantic.dev/docs/validation/latest/concepts/models/

# Assumptions and Data cleaning decisions:
# - The updates_region column was removed because it's originally from SQL Task 3 CTE output.
# - Missing JobTitle values stored as Nan were converted into None
# - because the schema allows NULL values for JobTitle.
# - I excluded rows with invalid or missing Region values because Region is defined as NOT NULL.
# - Bonus values were allowed to be NULL because Bonus is optional in a real setting and in this spec.
# - Only records passing all validation checks were included in the final validation DataFrame.

# Task 1 - Data Validation & Schema Design
# - This task validates employee records using Pydantic
# - before creating a cleaned dataframe for analysis.

df = pd.read_csv("joined_tables.csv")

# Removed extra column not required for Task 1.
df = df.drop(columns=["updates_region"], errors="ignore")

# Renamed column to match Pydantic model field name.
df = df.rename(columns={
    "ParticipantRecordID": "ParticipantRecordId"
})

# Replaced missing values with None for Pydantic validation.
df = df.replace({np.nan: None})

# Treated invalid Region codes as missing values.
df["Region"] = df["Region"].replace({
    0: None,
    "0": None
})

# Mapping numeric regions.
region_map ={
    1: "Inner London",
    2: "Outer London",
    3: "South East",
    4: "South West",
    5: "East Anglia",
    6: "East Midlands",
    7: "West Midlands",
    8: "North West",
    9: "North & North East",
    10: "Scotland",
    11: "Northern Ireland",
    12: "Wales",
    15: "Mobile"
}

df["Region"] = df["Region"].map(region_map).fillna(df["Region"])

class EmployeeData(BaseModel):
    Install: int
    ParticipantRecordId: int
    JobTitle: Optional[str] = None
    Level: int
    Global_function_group_2020: int
    Basic_Salary: float
    Bonus: Optional[float] = None
    Basic_plus_Bonus_plus_Allowances_2020: Optional[float] = None
    XHR_Sector_Grouped:int
    emp_band: int
    Turnover_3_Bands: int
    Region: str
    sum_basic_bonus: Optional[float] = None
    is_sum_match_Basic_plus_Allowances_2020: Optional[int] = None

    @field_validator("Level")
    def check_level(cls, value):
        allowed_levels = [10, 11, 12, 13, 14, 15, 16,
                      20, 21, 22, 23, 24, 25]
        if value not in allowed_levels:
            raise ValueError("Invalid level")
        return value

    @field_validator("Global_function_group_2020")
    def check_function_group(cls, value):

        if value not in range(1, 29):
            raise ValueError("Invalid function group")

        return value

    @field_validator("Basic_Salary")
    def check_salary(cls, value):

        if value < 22000:
            raise ValueError("Salary below minimum")
        return value

    @field_validator("Bonus")
    def check_bonus(cls, value):
        if value is not None and value < 0:
            raise ValueError("Negative bonus")
        return value

    @field_validator("Basic_plus_Bonus_plus_Allowances_2020")
    def check_total_pay(cls, value):
        if value is not None and value < 22000:
            raise ValueError("Total pay below minimum")
        return value

    @field_validator("XHR_Sector_Grouped")
    def check_sector(cls, value):

        if value not in [1, 2, 3, 4]:
            raise ValueError("Invalid sector")

        return value

    @field_validator("emp_band")
    def check_emp_band(cls, value):

        if value not in [1, 2, 3]:
            raise ValueError("Invalid employee band")
        return value

    @field_validator("Turnover_3_Bands")
    def check_turnover_band(cls, value):

        if value not in [1, 2, 3]:
            raise ValueError("Invalid turnover band")

        return value

    @field_validator("Region")
    def check_region(cls, value):
        allowed_regions = [
            "Inner London", "Outer London", "South East", "South West",
            "East Anglia", "East Midlands", "West Midlands", "North West",
            "North & North East", "Scotland", "Northern Ireland", "Wales", "Mobile"
        ]
        if value not in allowed_regions:
            raise ValueError("Invalid region")
        return value

valid_rows = []
invalid_rows = []

# Validated each row against the schema.
# Each dataframe row is validated against the Pydantic schema.
# Valid rows are stored separately from invalid rows.
for index, row in df.iterrows():
    try:
        validated_row = EmployeeData(**row.to_dict())
        valid_rows.append(validated_row.model_dump())
    except ValidationError as e:
        invalid_rows.append({
            "row_index": index,
            "errors": e.errors()
        })

validated_df = pd.DataFrame(valid_rows)

print("Valid rows:", len(validated_df))
print("Invalid rows:", len(invalid_rows))
print(validated_df.head())
print(validated_df.info())
