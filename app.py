#!/usr/bin/env python3
"""
Flask Demo App mit Ping-Pong Endpoint
"""

from flask import Flask, jsonify
import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Basis-Route für die Anwendung"""
    return jsonify({
        'message': 'Willkommen zur Flask Demo App!',
        'endpoints': {
            '/': 'Diese Übersichtsseite',
            '/ping': 'Ping-Pong Endpoint',
            '/health': 'Health Check'
        }
    })

@app.route('/ping')
def ping():
    """Ping-Pong Endpoint"""
    return jsonify({
        'message': 'pong',
        'timestamp': datetime.datetime.now().isoformat(),
        'status': 'ok'
    })

@app.route('/health')
def health():
    """Health Check Endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'version': '1.0.0'
    })

if __name__ == '__main__':
    print("🚀 Starte Flask Demo App...")
    print("📍 Verfügbare Endpoints:")
    print("   • / - Übersichtsseite")
    print("   • /ping - Ping-Pong Endpoint")
    print("   • /health - Health Check")
    app.run(host='0.0.0.0', port=5000, debug=True)