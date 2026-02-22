from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class DataSourceConfig:
    input_data_path: Path
    output_data_path: Path


@dataclass(frozen=True)
class SparkConfig:
    app_name: str = "LocalPeopleRefiner"
    master: str = "local[*]"


@dataclass(frozen=True)
class LocalPipelineConfig:
    data_source: DataSourceConfig
    spark: SparkConfig
