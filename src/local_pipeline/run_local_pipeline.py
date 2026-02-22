from __future__ import annotations

import argparse
import sys
from pathlib import Path

from pyspark.sql import SparkSession

from local_pipeline.config import DataSourceConfig, LocalPipelineConfig, SparkConfig
from local_pipeline.people_pipeline_job import PeoplePipelineJob


def init_spark(config: SparkConfig) -> SparkSession:
    return SparkSession.builder.master(config.master).appName(config.app_name).getOrCreate()


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Local normalization and deduplication job")
    parser.add_argument("--input-dir", required=True, help="Path to input CSV directory")
    parser.add_argument("--output-dir", required=True, help="Path to output parquet directory")
    return parser.parse_args()


def main() -> None:
    print(f"Python Version: {sys.version}")

    args = parse_arguments()

    data_source_config = DataSourceConfig(
        input_data_path=Path(args.input_dir),
        output_data_path=Path(args.output_dir),
    )
    spark_config = SparkConfig()
    config = LocalPipelineConfig(data_source=data_source_config, spark=spark_config)

    csv_files = sorted(config.data_source.input_data_path.glob("*.csv"))
    if not csv_files:
        raise SystemExit(f"No CSV files found in: {config.data_source.input_data_path}")

    spark = init_spark(config.spark)
    job = PeoplePipelineJob(config, spark)

    print("Processing started...")
    try:
        stats = job.run()
        print("Processing finished...")
        print(f"input_files={len(csv_files)}")
        print(f"source_rows={stats.source_rows}")
        print(f"deduplicated_rows={stats.deduplicated_rows}")
        print(f"duplicates_removed={stats.duplicates_removed}")
        print(f"output_parquet={stats.output_path}")
    except Exception as exc:
        print("Processing failed...")
        print(exc)
        raise
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
