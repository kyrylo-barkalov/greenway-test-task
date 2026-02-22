import sys

from pyspark.sql import SparkSession


def main() -> None:
    spark = SparkSession.builder.getOrCreate()
    if len(sys.argv) < 2:
        raise SystemExit("Usage: spark-submit count_csv_rows.py s3://bucket/path/file.csv")

    s3_csv_path = sys.argv[1]
    df = spark.read.option("header", "true").csv(s3_csv_path)
    row_count = df.count()
    print(f"rows_uploaded={row_count}")
    spark.stop()


if __name__ == "__main__":
    main()
