# Docker Exercises - Hands-On Practice

## Exercise 1: Your First Container

**What you'll do:** Run a simple Linux container and play with it.

```bash
# Run Alpine Linux (it's tiny, only 8MB)
docker run -td alpine

# See it running
docker ps

# Login to the container
docker exec -it <container_id> sh

# Inside the container, try these:
hostname        # See container name
ls              # List files
pwd             # Where am I?
touch test.txt  # Create a file
ls              # See your file
exit            # Get out
```

**Now clean up:**
```bash
# Stop it
docker stop <container_id>

# Delete it
docker rm <container_id>
```

---

## Exercise 2: Port Forwarding

**What you'll do:** Run a web server and access it from your browser.

```bash
# Run Nginx web server
# -p 8080:80 means "map my computer's port 8080 to container's port 80"
docker run -td -p 8080:80 nginx

# Check it's running
docker ps

# Open browser and go to:
http://localhost:8080

# You should see "Welcome to nginx!"
```

**Try different ports:**
```bash
# Run another one on different port
docker run -td -p 9090:80 nginx

# Now you have two web servers:
# http://localhost:8080
# http://localhost:9090
```

**Clean up:**
```bash
# See all containers
docker ps

# Kill them all
docker rm -f $(docker ps -q)
```

---

## Exercise 3: Build Your First Docker Image

**What you'll do:** Make a simple Python app and put it in Docker.

**Step 1:** Create files

Create a folder called `myapp` and add these files:

**app.py**
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello! My app is running in Docker!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**requirements.txt**
```
flask
```

**Dockerfile**
```dockerfile
# Start with Python already installed
FROM python:3.8-slim

# Make a folder for our app
WORKDIR /app

# Copy our files
COPY requirements.txt .
COPY app.py .

# Install Flask
RUN pip install -r requirements.txt

# Tell Docker our app uses port 5000
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
```

**Step 2:** Build and run
```bash
# Build it (the dot means "current folder")
docker build -t myapp .

# Run it
docker run -td -p 5000:5000 myapp

# Test it
curl localhost:5000
# Or open browser: http://localhost:5000
```

---

## Exercise 4: Push to Docker Hub

**What you'll do:** Share your image so anyone can use it.

```bash
# Login to Docker Hub (create free account first at hub.docker.com)
docker login

# Tag your image with your username
docker tag myapp yourusername/myapp:1.0

# Push it
docker push yourusername/myapp:1.0

# Now delete local copy
docker rmi yourusername/myapp:1.0

# Pull and run from Docker Hub
docker run -td -p 5000:5000 yourusername/myapp:1.0
# It downloads and runs!
```

---

## Exercise 5: Docker Volumes (Save Your Data)

**The Problem:** When you delete a container, all its data is gone.

**The Solution:** Use volumes to save data outside the container.

### Part A: Named Volume
```bash
# Create a volume
docker volume create mydata

# Run container with volume attached
# -v means "attach volume mydata to folder /data in container"
docker run -td -v mydata:/data --name box1 alpine

# Login and create a file
docker exec -it box1 sh
cd /data
echo "This is important data!" > important.txt
cat important.txt
exit

# Kill the container
docker rm -f box1

# Start new container with same volume
docker run -td -v mydata:/data --name box2 alpine

# Check if file is still there
docker exec box2 cat /data/important.txt
# Yes! Data survived!
```

### Part B: Mount Your Local Folder
```bash
# Create a folder on your computer
mkdir mycode
echo "print('hello')" > mycode/test.py

# Run container with your folder mounted
docker run -td -v $(pwd)/mycode:/app --name dev python:3.8-slim sleep infinity

# Edit file on your computer
echo "print('updated!')" > mycode/test.py

# Run it in container - sees the update!
docker exec dev python /app/test.py
```

**When to use each:**
- **Named volumes** - For database data, uploaded files, anything important
- **Folder mounts** - For development, when you want to edit code live

---

## Exercise 6: Docker Networks

### Understanding Network Types

Docker has 3 main network types:

**1. Bridge (Default)**
- Each container gets its own IP address (like 172.17.0.2)
- Containers can talk to each other using IP
- You need `-p` to access from your computer
- **Use when:** Running regular apps

**2. Host**
- Container uses your computer's network directly
- No separate IP address
- No need for `-p` port mapping
- **Use when:** You need maximum performance
- **Warning:** Less isolated, less secure

**3. None**
- No network at all
- Container is completely isolated
- **Use when:** Running something that shouldn't access network

### Network Exercise

**Part A: Default Bridge Network**
```bash
# Run two containers
docker run -td --name web1 nginx
docker run -td --name web2 nginx

# Check their IPs
docker inspect web1 | grep IPAddress
docker inspect web2 | grep IPAddress

# They can ping each other by IP (not by name)
docker exec web1 ping <web2_ip>
```

**Part B: Custom Network (Better Way)**
```bash
# Create your own network
docker network create mynetwork

# Run containers on it
docker run -td --network mynetwork --name app1 nginx
docker run -td --network mynetwork --name app2 nginx

# Now they can talk by NAME (Docker gives DNS)
docker exec app1 ping app2
docker exec app1 curl http://app2
# This is magic! No need to remember IPs!
```

**Part C: Host Network**
```bash
# Run with host network
docker run -td --network host nginx

# Access directly at localhost:80 (no port mapping needed!)
curl localhost:80
```

**Network Commands:**
```bash
# See all networks
docker network ls

# Details about a network
docker network inspect mynetwork

# Delete network
docker network rm mynetwork
```

---

## Exercise 7: Multi-Container App

**What you'll build:** A backend API and frontend that talk to each other.

**Backend (API):**

Create folder `backend/`:

**backend/app.py**
```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/message')
def message():
    return jsonify({"message": "Hello from backend!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**backend/requirements.txt**
```
flask
```

**backend/Dockerfile**
```dockerfile
FROM python:3.8-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
```

**Build and run:**
```bash
# Create network
docker network create appnet

# Build backend
cd backend
docker build -t backend .

# Run backend on network
docker run -td --network appnet --name backend backend
```

**Frontend (just test with curl):**
```bash
# Run alpine on same network
docker run -td --network appnet --name frontend alpine sleep infinity

# Test connection
docker exec frontend apk add curl  # Install curl
docker exec frontend curl http://backend:5000/api/message
# Should show: {"message": "Hello from backend!"}
```

**Key point:** Containers on the same network can talk using container names!

---

## Exercise 8: Data Persistence Challenge

**Challenge:** Create a simple todo app where todos survive container restarts.

**Step 1:** Create app

**app.py**
```python
from flask import Flask, request, jsonify
import json
import os

app = Flask(__name__)
TODO_FILE = '/data/todos.json'

def load_todos():
    if os.path.exists(TODO_FILE):
        with open(TODO_FILE, 'r') as f:
            return json.load(f)
    return []

def save_todos(todos):
    os.makedirs('/data', exist_ok=True)
    with open(TODO_FILE, 'w') as f:
        json.dump(todos, f)

@app.route('/todos', methods=['GET'])
def get_todos():
    return jsonify(load_todos())

@app.route('/todos', methods=['POST'])
def add_todo():
    todos = load_todos()
    todos.append(request.json['task'])
    save_todos(todos)
    return jsonify({"message": "Added!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Dockerfile**
```dockerfile
FROM python:3.8-slim
WORKDIR /app
COPY app.py .
RUN pip install flask
EXPOSE 5000
CMD ["python", "app.py"]
```

**Step 2:** Test with volume
```bash
# Create volume
docker volume create todos

# Build
docker build -t todoapp .

# Run with volume
docker run -td -p 5000:5000 -v todos:/data --name todo todoapp

# Add some todos
curl -X POST http://localhost:5000/todos -H "Content-Type: application/json" -d '{"task":"Learn Docker"}'
curl -X POST http://localhost:5000/todos -H "Content-Type: application/json" -d '{"task":"Build apps"}'

# See todos
curl http://localhost:5000/todos

# Kill container
docker rm -f todo

# Start new one with same volume
docker run -td -p 5000:5000 -v todos:/data --name todo2 todoapp

# Check - todos are still there!
curl http://localhost:5000/todos
```

---

## Exercise 9: Debug a Broken Container

**Scenario:** Your container won't start. Fix it!

**Broken Dockerfile:**
```dockerfile
FROM python:3.8-slim
WORKDIR /app
COPY app.py .
RUN pip install flask
EXPOSE 5000
CMD ["python", "ap.py"]  # TYPO HERE!
```

**How to debug:**
```bash
# Build it
docker build -t broken .

# Try to run
docker run -td -p 5000:5000 --name broken broken

# Check status
docker ps -a
# Shows: Exited

# Check logs
docker logs broken
# Shows: can't find ap.py

# Fix the Dockerfile, rebuild, try again
```

---

## Exercise 10: Clean Everything

**When your system is full of old containers and images:**

```bash
# See what's taking space
docker system df

# Stop all running containers
docker stop $(docker ps -q)

# Delete all containers
docker rm $(docker ps -aq)

# Delete all images
docker rmi $(docker images -q)

# Delete all volumes
docker volume prune

# Delete all networks
docker network prune

# Nuclear option - clean EVERYTHING
docker system prune -a --volumes
```

---

## Common Commands Cheat Sheet

```bash
# CONTAINERS
docker run -td <image>              # Start container
docker run -td -p 8080:80 <image>   # With port mapping
docker ps                           # Show running
docker ps -a                        # Show all
docker stop <id>                    # Stop container
docker start <id>                   # Start stopped container
docker rm <id>                      # Delete container
docker logs <id>                    # See logs
docker exec -it <id> sh             # Login to container

# IMAGES
docker images                       # List images
docker build -t <name> .            # Build from Dockerfile
docker rmi <image>                  # Delete image
docker tag <old> <new>              # Rename image
docker push <image>                 # Upload to Docker Hub
docker pull <image>                 # Download from Docker Hub

# VOLUMES
docker volume create <name>         # Create volume
docker volume ls                    # List volumes
docker volume rm <name>             # Delete volume
docker run -v <vol>:/path <image>   # Use volume

# NETWORKS
docker network create <name>        # Create network
docker network ls                   # List networks
docker network rm <name>            # Delete network
docker run --network <name> <image> # Use network

# CLEANUP
docker rm -f $(docker ps -aq)       # Delete all containers
docker rmi $(docker images -q)      # Delete all images
docker system prune -a              # Clean everything
```

---

## Assignments

### Assignment 1: Build a Web App
Create a Flask app that shows:
- Your name
- Current date and time
- A list of your favorite movies

Package it in Docker and push to Docker Hub.

### Assignment 2: Database with Volume
- Run a PostgreSQL container with a volume
- Create a table and add data
- Delete the container
- Start new container with same volume
- Verify data is still there

### Assignment 3: Multi-Container
Create two apps:
- Backend API (returns random jokes)
- Frontend (calls backend and displays joke)

Both on same custom network.

### Assignment 4: Network Comparison
Run the same app on:
1. Bridge network
2. Host network
3. Custom network

Document differences in access and performance.

### Assignment 5: Real Project
Build a simple blog:
- Backend API (Flask) with SQLite database
- Store database file in volume
- Use custom network
- Document everything
- Push all images to Docker Hub

---

## Tips

1. **Always name your containers** - easier to remember than IDs
   ```bash
   docker run --name myapp ...
   ```

2. **Use volumes for anything important** - data in containers disappears!

3. **Custom networks are better** - containers can talk using names

4. **Check logs when something breaks**
   ```bash
   docker logs <container>
   ```

5. **Clean up regularly** - Docker eats disk space
   ```bash
   docker system prune
   ```

---

That's it! Start with Exercise 1 and work your way up. Don't rush - try each exercise multiple times until it makes sense.
