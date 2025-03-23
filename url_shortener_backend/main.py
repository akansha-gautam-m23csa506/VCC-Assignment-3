import os
import random
import string
import json
from flask import Flask, jsonify, request, redirect
from flask_cors import CORS
from google.cloud import storage

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "http://34.93.82.237"}})

# Config
GCS_BUCKET = os.getenv("GCS_BUCKET")
DB_FILE = "shortened_urls.json"
shortened_urls = {}

# Initialize GCS client
storage_client = storage.Client()
bucket = storage_client.bucket(GCS_BUCKET)

def download_db_file():
    try:
        blob = bucket.blob(DB_FILE)
        blob.download_to_filename(DB_FILE)
        print("Downloaded DB from GCS.")
    except Exception as e:
        print(f"No existing DB found, starting fresh: {e}")
        with open(DB_FILE, 'w') as f:
            json.dump({}, f)

def upload_db_file():
    try:
        blob = bucket.blob(DB_FILE)
        blob.upload_from_filename(DB_FILE)
        print("Uploaded DB to GCS.")
    except Exception as e:
        print(f"Failed to upload DB: {e}")

def generate_short_url(length=6):
    chars = string.ascii_letters + string.digits
    short_url = ''.join(random.choice(chars) for _ in range(length))
    return short_url

@app.route('/shorten', methods=['POST'])
def shorten_url():
    data = request.json
    url = data.get('long_url')
    if not url:
        return jsonify({"error": "Missing 'long_url'"}), 400

    short_url = generate_short_url()
    while short_url in shortened_urls:
        short_url = generate_short_url()
    shortened_urls[short_url] = url

    # Save locally & upload to GCS
    with open(DB_FILE, 'w') as f:
        json.dump(shortened_urls, f)
    upload_db_file()

    return jsonify({"short_url": f"{request.url_root}{short_url}", "long_url": url})

@app.route('/urls', methods=['GET'])
def get_urls():
    return jsonify(shortened_urls)

@app.route('/<short_url>', methods=['GET'])
def redirect_to_url(short_url):
    long_url = shortened_urls.get(short_url)
    if not long_url:
        return jsonify({"error": f"URL for {short_url} not found"}), 404
    return redirect(long_url)

if __name__ == '__main__':
    try:
        # Download DB from GCS at startup
        download_db_file()
        with open(DB_FILE, 'r') as f:
            shortened_urls = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        shortened_urls = {}

    app.run(host='0.0.0.0', port=5000, debug=True)
