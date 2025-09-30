# Object-Centric AI API

A FastAPI-based machine learning service that uses PyTorch, CLIP, and Graph Neural Networks for object-centric AI inference. This service provides object detection and matching capabilities through a REST API.

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- CUDA-compatible GPU (recommended for better performance)
- At least 8GB RAM
- 10GB free disk space

### Installation

1. **Clone and navigate to the project:**
   ```bash
   cd /workspace
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Create checkpoint directory:**
   ```bash
   mkdir -p backend/checkpoints
   ```

### Running the Server

#### Option 1: Direct Python Execution
```bash
cd backend
python server.py
```

#### Option 2: Using Uvicorn (Recommended)
```bash
cd backend
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

#### Option 3: Using the provided startup script
```bash
chmod +x start_server.sh
./start_server.sh
```

The server will start on `http://localhost:8000`

### API Documentation

Once the server is running, visit:
- **Interactive API docs:** `http://localhost:8000/docs`
- **ReDoc documentation:** `http://localhost:8000/redoc`

## 📋 API Usage

### Endpoint: `/predict`

**Method:** POST  
**Content-Type:** application/json

**Request Body:**
```json
{
  "image_base64": "base64_encoded_image_string"
}
```

**Response:**
```json
{
  "num_kernels": 150,
  "matched_kernel_ids": ["uuid1", "uuid2", "uuid3"],
  "matched_scores": [0.95, 0.87, 0.82]
}
```

### Example Usage with curl:

```bash
# Convert image to base64 (Linux/Mac)
base64_image=$(base64 -i your_image.jpg)

# Send prediction request
curl -X POST "http://localhost:8000/predict" \
     -H "Content-Type: application/json" \
     -d "{\"image_base64\": \"$base64_image\"}"
```

### Example Usage with Python:

```python
import requests
import base64

# Load and encode image
with open("your_image.jpg", "rb") as image_file:
    image_base64 = base64.b64encode(image_file.read()).decode('utf-8')

# Send request
response = requests.post(
    "http://localhost:8000/predict",
    json={"image_base64": image_base64}
)

result = response.json()
print(f"Found {result['num_kernels']} kernels")
print(f"Best matches: {result['matched_kernel_ids']}")
```

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

1. **Start the service:**
   ```bash
   docker-compose up -d
   ```

2. **View logs:**
   ```bash
   docker-compose logs -f
   ```

3. **Stop the service:**
   ```bash
   docker-compose down
   ```

### Using Docker directly

1. **Build the image:**
   ```bash
   docker build -t object-ai-api .
   ```

2. **Run the container:**
   ```bash
   docker run -p 8000:8000 --gpus all object-ai-api
   ```

## 🔧 Configuration

### Environment Variables

- `CUDA_VISIBLE_DEVICES`: GPU device IDs to use (e.g., "0,1")
- `CHECKPOINT_PATH`: Path to model checkpoint file
- `MAX_KERNELS`: Maximum number of kernels in pool (default: 500)
- `PORT`: Server port (default: 8000)
- `HOST`: Server host (default: 0.0.0.0)

### Model Checkpoints

The server expects a checkpoint file at `backend/checkpoints/coco_ckpt_epoch_4.pth`. If you don't have a trained model:

1. **Train a model** using the training scripts (if available)
2. **Download a pre-trained checkpoint** and place it in the checkpoints directory
3. **Use a different checkpoint** by modifying `CHECKPOINT_PATH` in `server.py`

## 🚀 Production Deployment

### Using Gunicorn + Uvicorn

```bash
pip install gunicorn
gunicorn backend.server:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Using Nginx as Reverse Proxy

1. **Install Nginx:**
   ```bash
   sudo apt update
   sudo apt install nginx
   ```

2. **Create Nginx configuration:**
   ```bash
   sudo nano /etc/nginx/sites-available/object-ai-api
   ```

3. **Add configuration:**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

4. **Enable the site:**
   ```bash
   sudo ln -s /etc/nginx/sites-available/object-ai-api /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

### Using PM2 for Process Management

```bash
npm install -g pm2
pm2 start "uvicorn backend.server:app --host 0.0.0.0 --port 8000" --name object-ai-api
pm2 save
pm2 startup
```

## 🔍 Troubleshooting

### Common Issues

1. **CUDA out of memory:**
   - Reduce batch size or use CPU mode
   - Set `CUDA_VISIBLE_DEVICES=""` to force CPU usage

2. **Checkpoint not found:**
   - Ensure checkpoint file exists in `backend/checkpoints/`
   - Check file permissions

3. **Port already in use:**
   - Change port: `uvicorn server:app --port 8001`
   - Kill existing process: `lsof -ti:8000 | xargs kill -9`

4. **Dependencies installation fails:**
   - Update pip: `pip install --upgrade pip`
   - Install PyTorch separately: `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118`

### Performance Optimization

1. **GPU Memory:**
   - Monitor with `nvidia-smi`
   - Adjust `max_kernels` in KernelPool

2. **CPU Usage:**
   - Use multiple workers with Gunicorn
   - Enable async processing

3. **Memory Usage:**
   - Monitor with `htop` or `top`
   - Adjust kernel pool size

## 📊 Monitoring

### Health Check

```bash
curl http://localhost:8000/docs
```

### Logs

- **Development:** Logs appear in terminal
- **Production:** Use `docker-compose logs` or `pm2 logs`

### Metrics

Monitor these key metrics:
- Response time
- Memory usage
- GPU utilization
- Number of active kernels

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

[Add your license information here]

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the API documentation at `/docs`
3. Create an issue in the repository