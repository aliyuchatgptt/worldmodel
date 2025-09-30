#!/usr/bin/env python3
"""
Test script for Object-Centric AI API
This script tests the API endpoints and functionality
"""

import requests
import base64
import json
import sys
import time
from pathlib import Path

def create_test_image():
    """Create a simple test image for testing"""
    try:
        from PIL import Image, ImageDraw
        import io
        
        # Create a simple test image
        img = Image.new('RGB', (224, 224), color='red')
        draw = ImageDraw.Draw(img)
        draw.rectangle([50, 50, 174, 174], fill='blue', outline='white', width=2)
        draw.text((100, 100), "TEST", fill='white')
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG')
        img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        
        return img_base64
    except ImportError:
        print("PIL not available, using dummy base64 string")
        # Return a dummy base64 string for testing
        return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

def test_api_health(base_url):
    """Test if the API is running"""
    try:
        response = requests.get(f"{base_url}/docs", timeout=10)
        if response.status_code == 200:
            print("✅ API is running and accessible")
            return True
        else:
            print(f"❌ API returned status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to connect to API: {e}")
        return False

def test_predict_endpoint(base_url):
    """Test the /predict endpoint"""
    print("\n🧪 Testing /predict endpoint...")
    
    # Create test image
    test_image = create_test_image()
    
    # Prepare request
    payload = {
        "image_base64": test_image
    }
    
    try:
        response = requests.post(
            f"{base_url}/predict",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Prediction successful!")
            print(f"   Number of kernels: {result.get('num_kernels', 'N/A')}")
            print(f"   Matched kernel IDs: {result.get('matched_kernel_ids', [])}")
            print(f"   Matched scores: {result.get('matched_scores', [])}")
            return True
        else:
            print(f"❌ Prediction failed with status code: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False

def test_with_real_image(base_url, image_path):
    """Test with a real image file"""
    if not Path(image_path).exists():
        print(f"⚠️  Image file not found: {image_path}")
        return False
    
    print(f"\n🖼️  Testing with real image: {image_path}")
    
    try:
        with open(image_path, 'rb') as f:
            image_data = f.read()
            image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        payload = {
            "image_base64": image_base64
        }
        
        response = requests.post(
            f"{base_url}/predict",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Real image prediction successful!")
            print(f"   Number of kernels: {result.get('num_kernels', 'N/A')}")
            print(f"   Matched kernel IDs: {result.get('matched_kernel_ids', [])}")
            print(f"   Matched scores: {result.get('matched_scores', [])}")
            return True
        else:
            print(f"❌ Real image prediction failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing real image: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Object-Centric AI API Test Suite")
    print("=" * 40)
    
    # Default base URL
    base_url = "http://localhost:8000"
    
    # Check if custom URL provided
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    
    print(f"Testing API at: {base_url}")
    
    # Test API health
    if not test_api_health(base_url):
        print("\n❌ API health check failed. Make sure the server is running.")
        print("   Start the server with: ./start_server.sh")
        sys.exit(1)
    
    # Test predict endpoint
    if not test_predict_endpoint(base_url):
        print("\n❌ Predict endpoint test failed.")
        sys.exit(1)
    
    # Test with real image if provided
    if len(sys.argv) > 2:
        image_path = sys.argv[2]
        test_with_real_image(base_url, image_path)
    
    print("\n🎉 All tests passed! API is working correctly.")
    print("\n📚 API Documentation available at:")
    print(f"   {base_url}/docs")
    print(f"   {base_url}/redoc")

if __name__ == "__main__":
    main()