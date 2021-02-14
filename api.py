from flask import Flask, request, jsonify
from transformers import pipeline
import argparse


app = Flask(__name__)
nlp = pipeline("sentiment-analysis")

@app.route('/analysis', methods=['POST'])
def analyse_sentiment():
        request_data = request.get_json()
        results = []
        if 'sentences' not in request_data:
            return "Malformed json ", 400

        for sentence in request_data['sentences']:
            results.append(nlp(sentence)[0])
        return jsonify(results)

if __name__ == "__main__":
        app.run(host='0.0.0.0')
