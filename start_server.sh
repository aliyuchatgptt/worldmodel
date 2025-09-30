#!/bin/bash

# Object-Centric AI API Startup Script
# This script helps you start the server with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
HOST="0.0.0.0"
PORT="8000"
WORKERS="1"
RELOAD="false"
LOG_LEVEL="info"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST        Host to bind to (default: 0.0.0.0)"
    echo "  -p, --port PORT        Port to bind to (default: 8000)"
    echo "  -w, --workers WORKERS  Number of worker processes (default: 1)"
    echo "  -r, --reload           Enable auto-reload for development"
    echo "  -l, --log-level LEVEL  Log level (default: info)"
    echo "  -d, --docker           Run using Docker"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start with defaults"
    echo "  $0 -p 8080 -r                        # Start on port 8080 with reload"
    echo "  $0 -w 4 -l debug                     # Start with 4 workers and debug logging"
    echo "  $0 -d                                # Start using Docker"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -w|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -r|--reload)
            RELOAD="true"
            shift
            ;;
        -l|--log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        -d|--docker)
            USE_DOCKER="true"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [ ! -f "backend/server.py" ]; then
    print_error "server.py not found. Please run this script from the project root directory."
    exit 1
fi

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found. Please ensure you're in the project root directory."
    exit 1
fi

print_status "Starting Object-Centric AI API..."

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p backend/checkpoints
mkdir -p logs

# Check if using Docker
if [ "$USE_DOCKER" = "true" ]; then
    print_status "Starting with Docker..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if docker-compose is available
    if command -v docker-compose &> /dev/null; then
        print_status "Using docker-compose..."
        docker-compose up --build
    else
        print_status "Using docker build and run..."
        docker build -t object-ai-api .
        docker run -p $PORT:8000 -v $(pwd)/backend/checkpoints:/app/backend/checkpoints object-ai-api
    fi
else
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3.8 or higher."
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    REQUIRED_VERSION="3.8"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        print_error "Python $REQUIRED_VERSION or higher is required. Found: $PYTHON_VERSION"
        exit 1
    fi
    
    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    print_status "Activating virtual environment..."
    source venv/bin/activate
    
    # Install dependencies
    print_status "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Check if uvicorn is installed
    if ! command -v uvicorn &> /dev/null; then
        print_status "Installing uvicorn..."
        pip install uvicorn[standard]
    fi
    
    # Build uvicorn command
    UVICORN_CMD="uvicorn backend.server:app --host $HOST --port $PORT --log-level $LOG_LEVEL"
    
    if [ "$RELOAD" = "true" ]; then
        UVICORN_CMD="$UVICORN_CMD --reload"
        print_warning "Auto-reload is enabled. This is for development only."
    fi
    
    if [ "$WORKERS" -gt 1 ]; then
        UVICORN_CMD="$UVICORN_CMD --workers $WORKERS"
        print_status "Starting with $WORKERS workers..."
    fi
    
    print_success "Starting server on http://$HOST:$PORT"
    print_status "API documentation will be available at http://$HOST:$PORT/docs"
    print_status "Press Ctrl+C to stop the server"
    
    # Start the server
    eval $UVICORN_CMD
fi