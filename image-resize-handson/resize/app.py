import io
import os
import urllib.parse

import boto3
from PIL import Image

s3 = boto3.client("s3")

RESIZED_BUCKET = os.environ["RESIZED_BUCKET"]

# リサイズ設定
THUMBNAIL_SIZE = (150, 150)
MEDIUM_WIDTH = 800


def lambda_handler(event, context):
    """
    S3にJPG画像がアップロードされたら呼ばれる。
    - thumbnail/xxx.jpg : 150x150のサムネイル
    - medium/xxx.jpg    : 幅800pxの中サイズ
    を作成してリサイズ済みバケットに保存する。
    """
    record = event["Records"][0]
    source_bucket = record["s3"]["bucket"]["name"]
    # ファイル名にスペースや日本語が含まれる場合のデコード
    key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

    print(f"Processing: s3://{source_bucket}/{key}")

    # S3から元画像を取得
    response = s3.get_object(Bucket=source_bucket, Key=key)
    image_data = response["Body"].read()

    # Pillowで画像を開く
    image = Image.open(io.BytesIO(image_data))

    # PNG等の場合はRGBに変換（JPEGはアルファチャンネル非対応）
    if image.mode in ("RGBA", "P"):
        image = image.convert("RGB")

    filename = os.path.basename(key)


    thumbnail = _make_thumbnail(image, THUMBNAIL_SIZE)
    _upload(thumbnail, RESIZED_BUCKET, f"thumbnail/{filename}")

    medium = _make_medium(image, MEDIUM_WIDTH)
    _upload(medium, RESIZED_BUCKET, f"medium/{filename}")

    print(f"Done: thumbnail/medium saved to s3://{RESIZED_BUCKET}/")

    return {"status": "ok", "key": key}


def _make_thumbnail(image: Image.Image, size: tuple) -> Image.Image:
    """アスペクト比を維持しながら中央クロップしてサムネイルを作成する"""
    thumb = image.copy()
    thumb.thumbnail((size[0] * 2, size[1] * 2))  # 先に縮小してからクロップ
    width, height = thumb.size
    left = (width - size[0]) / 2
    top = (height - size[1]) / 2
    right = left + size[0]
    bottom = top + size[1]
    return thumb.crop((left, top, right, bottom))


def _make_medium(image: Image.Image, max_width: int) -> Image.Image:
    """幅をmax_widthに合わせてアスペクト比を維持してリサイズする"""
    width, height = image.size
    if width <= max_width:
        # 元画像が小さい場合はそのまま返す
        return image.copy()
    ratio = max_width / width
    new_height = int(height * ratio)
    return image.resize((max_width, new_height), Image.LANCZOS)


def _upload(image: Image.Image, bucket: str, key: str) -> None:
    """PIL ImageをS3にアップロードする"""
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=85)
    buffer.seek(0)
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=buffer,
        ContentType="image/jpeg",
    )
    print(f"Uploaded: s3://{bucket}/{key}")
