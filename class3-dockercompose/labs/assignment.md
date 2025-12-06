# Docker Networks Assignment

## Assignment Overview
Create a GitHub repository for this bootcamp and add your assignments to it. Share the repository link in the Discord channel.

---

## Assignment Tasks

### Task 1: Create Two Isolated Application Stacks

You need to set up **two different application stacks** on the **same machine**, each with their own network for isolation.

#### Stack 1: Flask + PostgreSQL
- **Application**: Flask (Python web application)
- **Database**: PostgreSQL
- **Network**: network-one

#### Stack 2: WordPress + MySQL
- **Application**: WordPress (PHP CMS)
- **Database**: MySQL
- **Network**: network-two

---

## Part A: Same Network Setup

### Step 1: Create Network One
```bash
docker network create network-one
```

### Step 2: Run Flask and PostgreSQL on Network One
```bash
# Run PostgreSQL container
docker run -d \
  --name flask-db \
  --network network-one \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=flaskdb \
  postgres:14

# Run Flask container (you can use any Flask image or build your own)
docker run -d \
  --name flask-app \
  --network network-one \
  -p 5000:5000 \
  <your-flask-image>
```

### Step 3: Verify Flask can connect to PostgreSQL
```bash
# Login to Flask container
docker exec -it flask-app sh

# Try to ping the database by name
ping flask-db

# Try DNS resolution
nslookup flask-db

# Exit
exit
```

### Step 4: Run WordPress and MySQL on Network One (Same Network)
```bash
# Run MySQL container
docker run -d \
  --name wordpress-db \
  --network network-one \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=wordpress \
  mysql:8.0

# Run WordPress container
docker run -d \
  --name wordpress-app \
  --network network-one \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=wordpress-db \
  -e WORDPRESS_DB_USER=root \
  -e WORDPRESS_DB_PASSWORD=password \
  -e WORDPRESS_DB_NAME=wordpress \
  wordpress:latest
```

### Step 5: Test Cross-Stack Communication
```bash
# Login to Flask container
docker exec -it flask-app sh

# Try to ping WordPress database (this should WORK - same network)
ping wordpress-db

# Exit
exit
```

**Document**: Take screenshots showing successful ping between Flask and WordPress containers.

---

## Part B: Different Networks Setup (Isolation)

### Step 1: Clean Up Previous Setup
```bash
docker rm -f flask-app flask-db wordpress-app wordpress-db
docker network rm network-one
```

### Step 2: Create Two Separate Networks
```bash
docker network create network-one
docker network create network-two
```

### Step 3: Run Flask Stack on Network One
```bash
# PostgreSQL
docker run -d \
  --name flask-db \
  --network network-one \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=flaskdb \
  postgres:14

# Flask App
docker run -d \
  --name flask-app \
  --network network-one \
  -p 5000:5000 \
  <your-flask-image>
```

### Step 4: Run WordPress Stack on Network Two
```bash
# MySQL
docker run -d \
  --name wordpress-db \
  --network network-two \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=wordpress \
  mysql:8.0

# WordPress
docker run -d \
  --name wordpress-app \
  --network network-two \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=wordpress-db \
  -e WORDPRESS_DB_USER=root \
  -e WORDPRESS_DB_PASSWORD=password \
  -e WORDPRESS_DB_NAME=wordpress \
  wordpress:latest
```

### Step 5: Test Isolation
```bash
# Login to Flask container
docker exec -it flask-app sh

# Try to ping Flask database (should WORK - same network)
ping flask-db

# Try to ping WordPress database (should FAIL - different network)
ping wordpress-db

# Exit
exit
```

**Document**: Take screenshots showing:
- Successful ping to flask-db
- Failed ping to wordpress-db (isolation working)

---

## What to Document

Create a document (Markdown, Word, or PDF) with the following:

1. **Setup Commands**: All commands you used for both parts
2. **Screenshots**: 
   - Docker network ls output
   - Successful communication within same network
   - Failed communication between different networks
   - Docker ps showing all running containers
3. **Learnings**: Write 3-5 sentences explaining:
   - Why custom networks are important
   - How network isolation works
   - Real-world use case for this setup

---

## Submission

1. Create a GitHub repository named `devops-bootcamp` or similar
2. Create a folder: `assignment-docker-networks`
3. Add your documentation file
4. Add a README.md with your learnings
5. Share the repository link in the Discord channel

---

## Expected Outcome

By completing this assignment, you will understand:
- How Docker networks provide isolation between applications
- How containers on the same network can communicate by name
- Why you should always use custom networks instead of default bridge
- Real-world scenario: Multiple teams running different apps on same machine

---

## Bonus Challenge (Optional)

Create a `docker-compose.yml` file that sets up both stacks with proper network isolation automatically.

---

## Tips

- Use `docker logs <container-name>` to troubleshoot connection issues
- Use `docker inspect <container-name>` to check network configuration
- If PostgreSQL or MySQL takes time to start, wait 30 seconds before testing connections
- Make sure Flask app is configured to connect to `flask-db` as hostname
- WordPress will automatically configure itself to connect to MySQL

---

## Questions?

If you get stuck, ask in the Discord channel. Remember: the goal is to understand network isolation, not just complete the task!
