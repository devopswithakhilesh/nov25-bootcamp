# Load Testing Guide

This guide explains how to perform load testing on the Flask application using the included `load_test.py` script.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Testing Modes](#testing-modes)
- [Usage Examples](#usage-examples)
- [Understanding the Output](#understanding-the-output)
- [Load Testing Strategy](#load-testing-strategy)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Python 3.9 or higher
- `requests` library
- Network access to the application

## Installation

1. Navigate to the app directory:
```bash
cd /Users/akhilesh/projects/nov25-bootcamp/class13-14/app
```

2. Install required dependencies:
```bash
pip install -r load_test_requirements.txt
```

3. Make the script executable (optional):
```bash
chmod +x load_test.py
```

---

## Testing Modes

The load test script supports three different modes:

### 1. **User Mode** (Default)
Simulates N concurrent users, each making R requests. This mimics real user behavior where multiple users access the application simultaneously.

**Use Case**: Testing how the application handles concurrent user sessions.

### 2. **RPS Mode** (Requests Per Second)
Maintains a constant rate of requests per second for a specified duration. The script precisely schedules requests to achieve the target RPS.

**Use Case**: Testing sustained load at specific throughput levels.

### 3. **RPM Mode** (Requests Per Minute)
Similar to RPS mode but specified in requests per minute. Automatically converts to RPS internally.

**Use Case**: When you think in terms of requests per minute (e.g., "I expect 6000 requests per minute during peak hours").

---

## Usage Examples

### User Mode Examples

#### Light Load (10 users, 20 requests each = 200 total)
```bash
python load_test.py https://class15.akhileshmishra.tech -u 10 -r 20
```

#### Medium Load with Gradual Ramp-up
```bash
python load_test.py https://class15.akhileshmishra.tech -u 50 -r 50 --ramp-up 10
```
- 50 concurrent users
- Each user makes 50 requests
- Users start gradually over 10 seconds
- Total: 2,500 requests

#### Heavy Load (Stress Test)
```bash
python load_test.py https://class15.akhileshmishra.tech -u 100 -r 100 --ramp-up 20
```
- 100 concurrent users
- Each user makes 100 requests
- Users start gradually over 20 seconds
- Total: 10,000 requests

---

### RPS Mode Examples

#### Light Load (10 requests/second for 1 minute)
```bash
python load_test.py https://class15.akhileshmishra.tech --rps 10 --duration 60
```
- Maintains exactly 10 requests/second
- Runs for 60 seconds
- Total: ~600 requests

#### Medium Load (50 requests/second for 2 minutes)
```bash
python load_test.py https://class15.akhileshmishra.tech --rps 50 --duration 120
```
- Maintains exactly 50 requests/second
- Runs for 120 seconds
- Total: ~6,000 requests

#### Heavy Load (100 requests/second for 5 minutes)
```bash
python load_test.py https://class15.akhileshmishra.tech --rps 100 --duration 300
```
- Maintains exactly 100 requests/second
- Runs for 300 seconds
- Total: ~30,000 requests

#### Extreme Stress Test (200 requests/second)
```bash
python load_test.py https://class15.akhileshmishra.tech --rps 200 --duration 180 -u 50
```
- Maintains 200 requests/second
- Uses 50 worker threads
- Runs for 180 seconds
- Total: ~36,000 requests

---

### RPM Mode Examples

#### 600 requests/minute (= 10 RPS)
```bash
python load_test.py https://class15.akhileshmishra.tech --rpm 600 --duration 300
```
- Maintains 600 requests/minute (10/second)
- Runs for 5 minutes
- Total: ~3,000 requests

#### 3000 requests/minute (= 50 RPS)
```bash
python load_test.py https://class15.akhileshmishra.tech --rpm 3000 --duration 600
```
- Maintains 3,000 requests/minute (50/second)
- Runs for 10 minutes
- Total: ~30,000 requests

#### Peak Load: 6000 requests/minute (= 100 RPS)
```bash
python load_test.py https://class15.akhileshmishra.tech --rpm 6000 --duration 300
```
- Maintains 6,000 requests/minute (100/second)
- Runs for 5 minutes
- Total: ~30,000 requests

---

## Understanding the Output

### During Test Execution

The script shows real-time progress:

```
[2026-02-08 10:30:15] [INFO] Starting Load Test - RPS Mode
[2026-02-08 10:30:15] [INFO] Target: https://class15.akhileshmishra.tech
[2026-02-08 10:30:15] [INFO] Target RPS: 50.0
[2026-02-08 10:30:15] [INFO] Duration: 120s
[2026-02-08 10:30:15] [INFO] Total Requests: ~6000
[2026-02-08 10:30:15] [INFO] Worker Threads: 10
[2026-02-08 10:30:15] [INFO] Started 10 worker threads
[2026-02-08 10:30:20] [INFO] Progress: 250/6000 (48.5 RPS)
```

### Final Summary

After completion, you'll see detailed metrics:

```
================================================================================
LOAD TEST SUMMARY
================================================================================
Duration:              120.45s
Total Requests:        6000
Successful:            5950 (99.17%)
Failed:                50
Requests/sec:          49.81

--- RESPONSE TIMES (seconds) ---
Min:                   0.035s
Max:                   2.450s
Average:               0.156s
Median:                0.142s
95th Percentile:       0.298s
99th Percentile:       0.512s

--- STATUS CODES ---
200:                   5800
302:                   150
502:                   45
0:                     5

--- ENDPOINT BREAKDOWN ---

/
  Requests:            1800
  Success Rate:        99.50%
  Avg Response Time:   0.125s

/create
  Requests:            1200
  Success Rate:        98.75%
  Avg Response Time:   0.189s

/post/{id}
  Requests:            1500
  Success Rate:        99.33%
  Avg Response Time:   0.142s
```

### Key Metrics Explained

| Metric | What It Means |
|--------|---------------|
| **Success Rate** | Percentage of requests that returned 2xx or 302 status |
| **Requests/sec** | Actual throughput achieved (compare with target RPS) |
| **Average Response Time** | Mean time to receive response |
| **Median Response Time** | 50% of requests completed faster than this |
| **95th Percentile (P95)** | 95% of requests completed faster than this |
| **99th Percentile (P99)** | 99% of requests completed faster than this |

---

## Load Testing Strategy

### Step 1: Baseline Test (Low Load)
Start with minimal load to verify everything works:

```bash
python load_test.py https://class15.akhileshmishra.tech --rps 5 --duration 60
```

**Expected Results**:
- ✅ Success rate: 100%
- ✅ P95 response time: < 500ms
- ✅ No errors

---

### Step 2: Normal Load Test
Test typical production load:

```bash
python load_test.py https://class15.akhileshmishra.tech --rps 20 --duration 120
```

**Expected Results**:
- ✅ Success rate: > 99%
- ✅ P95 response time: < 1s
- ✅ Minimal errors (< 1%)

---

### Step 3: Peak Load Test
Simulate peak traffic hours:

```bash
python load_test.py https://class15.akhileshmishra.tech --rps 50 --duration 300
```

**Watch For**:
- 🔍 Response times increasing
- 🔍 Error rates rising
- 🔍 Database connection issues
- 🔍 Memory/CPU usage on server

---

### Step 4: Stress Test (Find Breaking Point)
Gradually increase load until you find the breaking point:

```bash
# Start at 100 RPS
python load_test.py https://class15.akhileshmishra.tech --rps 100 --duration 300

# If successful, try 150 RPS
python load_test.py https://class15.akhileshmishra.tech --rps 150 --duration 300

# Keep increasing until you see failures
python load_test.py https://class15.akhileshmishra.tech --rps 200 --duration 300
```

**Breaking Point Indicators**:
- ❌ Success rate drops below 95%
- ❌ P95 response time > 3s
- ❌ Frequent 502/503 errors
- ❌ Database connection pool exhausted

---

### Step 5: Endurance Test (Soak Test)
Test stability over extended period:

```bash
python load_test.py https://class15.akhileshmishra.tech --rps 30 --duration 1800
```

**Watch For**:
- 🔍 Memory leaks (increasing response times)
- 🔍 Database connection leaks
- 🔍 Disk space issues (logs)
- 🔍 Performance degradation over time

---

## What Each Endpoint Does

The script randomly hits these endpoints:

| Endpoint | Method | Action | Weight |
|----------|--------|--------|--------|
| `/` | GET | View home page with all posts | 30% |
| `/create` | POST | Create a new post (writes to DB) | 20% |
| `/post/{id}` | GET | View specific post | 25% |
| `/create` | GET | View create post form | 15% |
| `/celery` | GET | View celery worker page | 10% |

**Note**: 20% of requests write to the database (POST to `/create`), which is more resource-intensive.

---

## Monitoring During Tests

### On AWS Console

Monitor these metrics during load tests:

1. **ECS Service Metrics**:
   - CPU utilization
   - Memory utilization
   - Task count (check if autoscaling triggers)

2. **ALB Metrics**:
   - Target response time
   - Healthy/unhealthy target count
   - Request count
   - HTTP 5xx errors

3. **RDS Metrics**:
   - Database connections
   - CPU utilization
   - Read/write latency
   - Freeable memory

4. **ElastiCache (Redis) Metrics**:
   - CPU utilization
   - Network bytes in/out
   - Cache hits/misses

### Expected Behavior

**Healthy System**:
- ECS tasks remain healthy
- ALB shows all targets healthy
- Database connections stable (< 50% of max)
- Response times consistent
- No 502/503 errors

**System Under Stress**:
- ECS autoscaling triggers (task count increases)
- Response times increase but remain reasonable
- Success rate stays > 95%
- Database connections increase but don't max out

**System Failing**:
- Health checks failing
- Tasks being replaced frequently
- High rate of 502/503 errors
- Database connection pool exhausted
- Response times > 5s

---

## Troubleshooting

### Problem: High Failure Rate (> 5%)

**Symptoms**: Many 502, 503, or timeout errors

**Possible Causes**:
1. **Nginx can't reach Flask** - Check Service Connect DNS, security groups
2. **Database connection pool exhausted** - Increase RDS max_connections
3. **Tasks being killed** - Health checks failing, increase health check timeout
4. **Not enough ECS tasks** - Check autoscaling settings

**Solution**:
```bash
# Reduce load and test incrementally
python load_test.py https://class15.akhileshmishra.tech --rps 10 --duration 60
```

---

### Problem: Slow Response Times (P95 > 2s)

**Symptoms**: High percentile response times

**Possible Causes**:
1. **Database queries slow** - Missing indexes, inefficient queries
2. **CPU/Memory pressure** - Tasks need more resources
3. **Network latency** - ALB to ECS or ECS to RDS
4. **Cold start issues** - New tasks starting up

**Investigation**:
```bash
# Check which endpoints are slow
# Look at the endpoint breakdown in test results
```

---

### Problem: Connection Errors

**Symptoms**: Many requests fail with "Connection Error"

**Possible Causes**:
1. **ALB not accessible** - Security group or DNS issue
2. **SSL/TLS issues** - Certificate problems
3. **Rate limiting** - WAF or ALB connection limits

**Solution**:
```bash
# Verify connectivity first
curl -I https://class15.akhileshmishra.tech

# Test with lower concurrency
python load_test.py https://class15.akhileshmishra.tech --rps 5 --duration 30
```

---

### Problem: Script Stops or Hangs

**Symptoms**: Script freezes or stops responding

**Possible Causes**:
1. **Too many concurrent workers** - Reduce worker count
2. **System resource exhaustion** - Script consuming too much memory/CPU locally

**Solution**:
```bash
# Reduce worker count (default is 10, max is 50)
python load_test.py https://class15.akhileshmishra.tech --rps 100 --duration 300 -u 20

# For very high RPS, use more workers
python load_test.py https://class15.akhileshmishra.tech --rps 500 --duration 60 -u 50
```

---

## Best Practices

### ✅ DO

1. **Start small** - Begin with low load and gradually increase
2. **Monitor everything** - Watch AWS metrics during tests
3. **Test incrementally** - Don't jump from 10 RPS to 1000 RPS
4. **Run multiple times** - Ensure results are consistent
5. **Test during different times** - Consider time zones, business hours
6. **Document results** - Keep track of what load your system can handle
7. **Use RPS mode for sustained load** - More predictable than user mode

### ❌ DON'T

1. **Don't test production without warning** - Coordinate with team
2. **Don't run tests from unreliable network** - Use stable connection
3. **Don't ignore errors** - Investigate every failure
4. **Don't test only happy path** - Script already tests various endpoints
5. **Don't run extremely long tests without monitoring** - Watch for issues
6. **Don't forget to stop autoscaling** - It will cost money

---

## Example Testing Session

Here's a complete testing workflow:

```bash
# 1. Baseline - Verify everything works
python load_test.py https://class15.akhileshmishra.tech --rps 5 --duration 60

# 2. Light load - Typical usage
python load_test.py https://class15.akhileshmishra.tech --rps 20 --duration 120

# 3. Medium load - Peak hours
python load_test.py https://class15.akhileshmishra.tech --rps 50 --duration 300

# 4. Heavy load - Find limits
python load_test.py https://class15.akhileshmishra.tech --rps 100 --duration 300

# 5. Stress test - Push to breaking point
python load_test.py https://class15.akhileshmishra.tech --rps 150 --duration 180

# 6. If still stable, keep increasing
python load_test.py https://class15.akhileshmishra.tech --rps 200 --duration 180

# 7. Endurance test at comfortable load (70% of max)
python load_test.py https://class15.akhileshmishra.tech --rps 70 --duration 1800
```

---

## Command Line Options Reference

```
usage: load_test.py [-h] [-u USERS] [-r REQUESTS] [--ramp-up RAMP_UP]
                    [--rps RPS] [--rpm RPM] [--duration DURATION]
                    url

positional arguments:
  url                   Base URL (e.g., https://class15.akhileshmishra.tech)

optional arguments:
  -h, --help            Show help message
  -u, --users USERS     Number of concurrent users/workers (default: 10)
  -r, --requests REQUESTS
                        Requests per user in user mode (default: 10)
  --ramp-up RAMP_UP     Ramp-up time in seconds for user mode (default: 0)
  --rps RPS             Requests per second (requires --duration)
  --rpm RPM             Requests per minute (requires --duration)
  --duration DURATION   Test duration in seconds (for RPS/RPM mode)
```

---

## Quick Reference Card

| Test Type | Command | Use Case |
|-----------|---------|----------|
| **Quick smoke test** | `--rps 5 --duration 60` | Verify app works |
| **Normal load** | `--rps 20 --duration 120` | Typical traffic |
| **Peak load** | `--rps 50 --duration 300` | Rush hour traffic |
| **Stress test** | `--rps 100 --duration 300` | Find breaking point |
| **Endurance test** | `--rps 30 --duration 1800` | Stability check |
| **User simulation** | `-u 50 -r 100 --ramp-up 20` | Concurrent users |

---

## Additional Resources

- Monitor ECS metrics: AWS Console → ECS → Clusters → Services → Metrics
- Monitor ALB metrics: AWS Console → EC2 → Load Balancers → Monitoring
- Monitor RDS metrics: AWS Console → RDS → Databases → Monitoring
- View application logs: CloudWatch → Log Groups → /ecs/...

---

## Questions?

Common questions and answers:

**Q: How many RPS can my application handle?**
A: Run incremental tests starting from 10 RPS and doubling until you see failures.

**Q: Should I use user mode or RPS mode?**
A: RPS mode for sustained load testing, user mode for concurrent user simulation.

**Q: What's a good success rate?**
A: Aim for > 99% under normal load, > 95% under stress.

**Q: How long should I run tests?**
A: Start with 60s, then 300s, then 1800s for endurance testing.

**Q: Can I stop a test mid-way?**
A: Yes, press Ctrl+C and it will gracefully stop and show results.

---

**Happy Load Testing! 🚀**
