import random
import string
import json
from flask import Flask, jsonify, request, redirect
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "http://34.93.82.237"}})

shortened_urls = {}

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

    with open('shortened_urls.json', 'w') as f:
        json.dump(shortened_urls, f)

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
        with open('shortened_urls.json', 'r') as f:
            shortened_urls = json.load(f)
    except FileNotFoundError:
        pass
    app.run(host='0.0.0.0', port=5000, debug=True)