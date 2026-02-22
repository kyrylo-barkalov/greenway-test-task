from __future__ import annotations

from dataclasses import dataclass

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.sql.window import Window

from local_pipeline.config import LocalPipelineConfig


@dataclass
class PipelineStats:
    source_rows: int
    deduplicated_rows: int
    duplicates_removed: int
    output_path: str


class PeoplePipelineJob:
    def __init__(self, config: LocalPipelineConfig, spark: SparkSession) -> None:
        self.config = config
        self.spark = spark

    def _build_dedup_key(self) -> F.Column:
        normalized_full_name = F.concat_ws(
            " ",
            F.coalesce(F.col("first_name"), F.lit("")),
            F.coalesce(F.col("last_name"), F.lit("")),
        )
        return F.sha2(
            F.concat_ws(
                "|",
                normalized_full_name,
                F.coalesce(F.col("phone"), F.lit("")),
                F.coalesce(F.col("email"), F.lit("")),
            ),
            256,
        )

    def _normalize(self, df: DataFrame) -> DataFrame:
        def empty_to_null(column: str) -> F.Column:
            return F.when(F.length(F.trim(F.col(column))) == 0, F.lit(None)).otherwise(F.trim(F.col(column)))

        normalized = (
            df
            .withColumn("first_name", F.initcap(F.lower(empty_to_null("first_name"))))
            .withColumn("last_name", F.initcap(F.lower(empty_to_null("last_name"))))
            .withColumn("email", F.lower(empty_to_null("email")))
            .withColumn("phone", F.regexp_replace(empty_to_null("phone"), r"[^0-9]", ""))
            .withColumn(
                "phone",
                F.when(F.length(F.col("phone")) == 10, F.concat(F.lit("1"), F.col("phone"))).otherwise(F.col("phone")),
            )
            .withColumn("address_line", F.lower(F.regexp_replace(empty_to_null("address_line"), r"[^a-zA-Z0-9 ]", "")))
            .withColumn("address_line", F.trim(F.regexp_replace(F.col("address_line"), r"\\s+", " ")))
            .withColumn("city", F.initcap(F.lower(empty_to_null("city"))))
            .withColumn("state", F.upper(empty_to_null("state")))
            .withColumn("postal_code", empty_to_null("postal_code"))
            .withColumn("country", F.upper(empty_to_null("country")))
            .withColumn("dedup_key", self._build_dedup_key())
        )

        return normalized.select(
            "first_name",
            "last_name",
            "email",
            "phone",
            "address_line",
            "city",
            "state",
            "postal_code",
            "country",
            "dedup_key",
        )

    def _deduplicate(self, df: DataFrame) -> DataFrame:
        quality_score = (
            F.when(F.col("address_line").isNotNull(), F.lit(1)).otherwise(F.lit(0))
            + F.when(F.col("postal_code").isNotNull(), F.lit(1)).otherwise(F.lit(0))
            + F.when(F.col("city").isNotNull(), F.lit(1)).otherwise(F.lit(0))
            + F.when(F.col("state").isNotNull(), F.lit(1)).otherwise(F.lit(0))
        )

        ranking_window = Window.partitionBy("dedup_key").orderBy(F.desc(quality_score), F.asc("first_name"), F.asc("last_name"))

        return (
            df
            .withColumn("row_rank", F.row_number().over(ranking_window))
            .filter(F.col("row_rank") == 1)
            .drop("row_rank")
            .select(
                "first_name",
                "last_name",
                "email",
                "phone",
                "address_line",
                "city",
                "state",
                "postal_code",
                "country",
                "dedup_key",
            )
        )

    def run(self) -> PipelineStats:
        input_glob = str(self.config.data_source.input_data_path / "*.csv")
        source_df = self.spark.read.option("header", "true").csv(input_glob)
        source_count = source_df.count()

        normalized_df = self._normalize(source_df)
        deduplicated_df = self._deduplicate(normalized_df)
        deduplicated_count = deduplicated_df.count()

        output_path = self.config.data_source.output_data_path
        output_path.parent.mkdir(parents=True, exist_ok=True)
        deduplicated_df.write.mode("overwrite").parquet(str(output_path))

        return PipelineStats(
            source_rows=source_count,
            deduplicated_rows=deduplicated_count,
            duplicates_removed=source_count - deduplicated_count,
            output_path=str(output_path),
        )
