#!/usr/bin/env python3
"""
Load Testing Script for Flask Application
Simulates concurrent users hitting various endpoints
"""

import requests
import random
import time
import threading
import statistics
from datetime import datetime
from collections import defaultdict
import sys

# Sample data for creating posts
POST_TITLES = [
    "Getting Started with Python",
    "Advanced Docker Tips",
    "Kubernetes Best Practices",
    "CI/CD Pipeline Tutorial",
    "AWS ECS Deployment Guide",
    "Terraform Infrastructure as Code",
    "Nginx Configuration Tips",
    "Flask Application Patterns",
    "Database Optimization Techniques",
    "Microservices Architecture",
    "Container Security Best Practices",
    "Load Balancing Strategies",
    "Monitoring and Logging Setup",
    "Cloud Cost Optimization",
    "DevOps Automation Tools",
    "Building Scalable Applications",
    "API Design Best Practices",
    "Redis Caching Strategies",
    "PostgreSQL Performance Tuning",
    "Blue-Green Deployment Guide"
]

POST_CONTENTS = [
    "This is a comprehensive guide covering best practices and common pitfalls. Learn from real-world examples and improve your skills with detailed explanations and code samples.",
    "In this article, we explore advanced techniques that will help you become more efficient. Includes practical code examples and real production scenarios.",
    "A deep dive into the subject with step-by-step instructions. Perfect for beginners and intermediate users alike. Updated with latest trends.",
    "Discover the latest trends and methodologies in modern development. Stay ahead with these proven strategies tested in production environments.",
    "This tutorial walks you through the entire process from start to finish. Includes troubleshooting tips and solutions for common issues.",
    "Learn how to implement these concepts in your production environment. Real-world case studies included with detailed metrics and outcomes.",
    "Master these techniques to improve performance and reliability. Tested in production environments with millions of users.",
    "A complete reference guide with examples and best practices. Save time with these proven solutions from industry experts.",
    "Understand the core concepts and how to apply them effectively. Includes diagrams, code snippets, and architectural patterns.",
    "Everything you need to know about this topic in one place. Regularly updated with latest information and community contributions."
]


class LoadTestMetrics:
    """Thread-safe metrics collector"""

    def __init__(self):
        self.lock = threading.Lock()
        self.requests_total = 0
        self.requests_success = 0
        self.requests_failed = 0
        self.response_times = []
        self.status_codes = defaultdict(int)
        self.endpoint_metrics = defaultdict(lambda: {
            'count': 0,
            'success': 0,
            'failed': 0,
            'response_times': []
        })
        self.errors = []
        self.start_time = None
        self.end_time = None

    def record_request(self, endpoint, status_code, response_time, success, error=None):
        """Record a request result"""
        with self.lock:
            self.requests_total += 1
            if success:
                self.requests_success += 1
            else:
                self.requests_failed += 1

            self.response_times.append(response_time)
            self.status_codes[status_code] += 1

            # Endpoint specific metrics
            self.endpoint_metrics[endpoint]['count'] += 1
            if success:
                self.endpoint_metrics[endpoint]['success'] += 1
            else:
                self.endpoint_metrics[endpoint]['failed'] += 1
            self.endpoint_metrics[endpoint]['response_times'].append(response_time)

            if error:
                self.errors.append((endpoint, error))

    def start(self):
        """Mark test start time"""
        self.start_time = time.time()

    def end(self):
        """Mark test end time"""
        self.end_time = time.time()

    def get_summary(self):
        """Generate test summary"""
        duration = self.end_time - self.start_time if self.end_time else 0

        summary = {
            'duration': duration,
            'total_requests': self.requests_total,
            'successful': self.requests_success,
            'failed': self.requests_failed,
            'success_rate': (self.requests_success / self.requests_total * 100) if self.requests_total > 0 else 0,
            'requests_per_second': self.requests_total / duration if duration > 0 else 0,
            'response_times': {
                'min': min(self.response_times) if self.response_times else 0,
                'max': max(self.response_times) if self.response_times else 0,
                'avg': statistics.mean(self.response_times) if self.response_times else 0,
                'median': statistics.median(self.response_times) if self.response_times else 0,
                'p95': self._percentile(self.response_times, 95) if self.response_times else 0,
                'p99': self._percentile(self.response_times, 99) if self.response_times else 0,
            },
            'status_codes': dict(self.status_codes),
            'endpoint_metrics': self.endpoint_metrics,
            'errors': self.errors[:10]  # First 10 errors
        }
        return summary

    def _percentile(self, data, percentile):
        """Calculate percentile"""
        if not data:
            return 0
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile / 100)
        return sorted_data[min(index, len(sorted_data) - 1)]


class LoadTester:
    """Load testing orchestrator"""

    def __init__(self, base_url, concurrent_users=10, requests_per_user=10, ramp_up_time=0,
                 rps=None, duration=None):
        self.base_url = base_url.rstrip('/')
        self.concurrent_users = concurrent_users
        self.requests_per_user = requests_per_user
        self.ramp_up_time = ramp_up_time
        self.rps = rps  # Requests per second
        self.duration = duration  # Test duration in seconds
        self.metrics = LoadTestMetrics()
        self.stop_flag = threading.Event()
        self.request_times = []  # For RPS mode
        self.lock = threading.Lock()

    def log(self, message, level="INFO"):
        """Print timestamped log message"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")

    def make_request(self, method, endpoint, data=None):
        """Make HTTP request and record metrics"""
        url = f"{self.base_url}{endpoint}"
        start_time = time.time()
        success = False
        status_code = 0
        error = None

        try:
            if method == 'GET':
                response = requests.get(url, timeout=30)
            elif method == 'POST':
                response = requests.post(url, data=data, timeout=30, allow_redirects=False)
            else:
                raise ValueError(f"Unsupported method: {method}")

            status_code = response.status_code
            success = status_code in [200, 201, 302]

        except requests.exceptions.Timeout:
            error = "Timeout"
            status_code = 0
        except requests.exceptions.ConnectionError:
            error = "Connection Error"
            status_code = 0
        except Exception as e:
            error = str(e)
            status_code = 0

        response_time = time.time() - start_time
        self.metrics.record_request(endpoint, status_code, response_time, success, error)

        return success, status_code, response_time

    def execute_random_action(self):
        """Execute a random API action"""
        action = random.choices(
            ['home', 'create_post', 'view_post', 'create_page', 'celery_page'],
            weights=[30, 20, 25, 15, 10],
            k=1
        )[0]

        if action == 'home':
            self.make_request('GET', '/')

        elif action == 'create_post':
            data = {
                'title': random.choice(POST_TITLES),
                'content': random.choice(POST_CONTENTS)
            }
            self.make_request('POST', '/create', data=data)

        elif action == 'view_post':
            post_id = random.randint(1, 50)
            self.make_request('GET', f'/post/{post_id}')

        elif action == 'create_page':
            self.make_request('GET', '/create')

        elif action == 'celery_page':
            self.make_request('GET', '/celery')

    def user_scenario(self, user_id):
        """Simulate one user's behavior"""
        for i in range(self.requests_per_user):
            if self.stop_flag.is_set():
                break

            self.execute_random_action()

            # Small random delay between requests
            time.sleep(random.uniform(0.1, 0.5))

    def rps_worker(self):
        """Worker thread for RPS mode - executes requests from queue"""
        while not self.stop_flag.is_set():
            with self.lock:
                if self.request_times:
                    target_time = self.request_times.pop(0)
                else:
                    time.sleep(0.01)
                    continue

            # Wait until it's time to send this request
            now = time.time()
            if target_time > now:
                time.sleep(target_time - now)

            if not self.stop_flag.is_set():
                self.execute_random_action()

    def run_rps_mode(self):
        """Run load test in RPS (requests per second) mode"""
        self.log("=" * 80)
        self.log(f"Starting Load Test - RPS Mode")
        self.log(f"Target: {self.base_url}")
        self.log(f"Target RPS: {self.rps}")
        self.log(f"Duration: {self.duration}s")
        self.log(f"Total Requests: ~{int(self.rps * self.duration)}")
        self.log(f"Worker Threads: {min(self.concurrent_users, 50)}")
        self.log("=" * 80)

        # Pre-calculate request times
        start_time = time.time()
        interval = 1.0 / self.rps
        num_requests = int(self.rps * self.duration)

        self.request_times = [start_time + (i * interval) for i in range(num_requests)]
        self.log(f"Scheduled {len(self.request_times)} requests")

        self.metrics.start()

        # Start worker threads
        workers = min(self.concurrent_users, 50)  # Cap at 50 workers
        threads = []

        try:
            for i in range(workers):
                thread = threading.Thread(target=self.rps_worker)
                thread.start()
                threads.append(thread)

            self.log(f"Started {workers} worker threads")

            # Monitor progress
            last_reported = 0
            while self.request_times and not self.stop_flag.is_set():
                time.sleep(1)
                completed = num_requests - len(self.request_times)
                if completed - last_reported >= self.rps * 5:  # Report every 5 seconds worth
                    elapsed = time.time() - start_time
                    current_rps = self.metrics.requests_total / elapsed if elapsed > 0 else 0
                    self.log(f"Progress: {completed}/{num_requests} ({current_rps:.1f} RPS)")
                    last_reported = completed

            # Signal workers to stop
            self.stop_flag.set()

            # Wait for workers to finish
            for thread in threads:
                thread.join(timeout=5)

        except KeyboardInterrupt:
            self.log("\nStopping load test...", "WARN")
            self.stop_flag.set()
            for thread in threads:
                thread.join(timeout=5)

        self.metrics.end()
        self.print_summary()

    def run(self):
        """Execute load test"""
        # Choose mode based on parameters
        if self.rps is not None and self.duration is not None:
            self.run_rps_mode()
        else:
            self.run_user_mode()

    def run_user_mode(self):
        """Execute load test in user mode (original mode)"""
        self.log("=" * 80)
        self.log(f"Starting Load Test - User Mode")
        self.log(f"Target: {self.base_url}")
        self.log(f"Concurrent Users: {self.concurrent_users}")
        self.log(f"Requests per User: {self.requests_per_user}")
        self.log(f"Total Requests: {self.concurrent_users * self.requests_per_user}")
        self.log(f"Ramp-up Time: {self.ramp_up_time}s")
        self.log("=" * 80)

        self.metrics.start()
        threads = []

        try:
            # Start threads with ramp-up
            ramp_delay = self.ramp_up_time / self.concurrent_users if self.concurrent_users > 0 else 0

            for user_id in range(self.concurrent_users):
                thread = threading.Thread(target=self.user_scenario, args=(user_id,))
                thread.start()
                threads.append(thread)

                if ramp_delay > 0:
                    time.sleep(ramp_delay)

                if (user_id + 1) % 10 == 0:
                    self.log(f"Started {user_id + 1}/{self.concurrent_users} users")

            self.log(f"All {self.concurrent_users} users started")

            # Wait for all threads to complete
            for thread in threads:
                thread.join()

        except KeyboardInterrupt:
            self.log("\nStopping load test...", "WARN")
            self.stop_flag.set()
            for thread in threads:
                thread.join(timeout=5)

        self.metrics.end()
        self.print_summary()

    def print_summary(self):
        """Print test results summary"""
        summary = self.metrics.get_summary()

        print("\n")
        print("=" * 80)
        print("LOAD TEST SUMMARY")
        print("=" * 80)
        print(f"Duration:              {summary['duration']:.2f}s")
        print(f"Total Requests:        {summary['total_requests']}")
        print(f"Successful:            {summary['successful']} ({summary['success_rate']:.2f}%)")
        print(f"Failed:                {summary['failed']}")
        print(f"Requests/sec:          {summary['requests_per_second']:.2f}")

        print("\n--- RESPONSE TIMES (seconds) ---")
        print(f"Min:                   {summary['response_times']['min']:.3f}s")
        print(f"Max:                   {summary['response_times']['max']:.3f}s")
        print(f"Average:               {summary['response_times']['avg']:.3f}s")
        print(f"Median:                {summary['response_times']['median']:.3f}s")
        print(f"95th Percentile:       {summary['response_times']['p95']:.3f}s")
        print(f"99th Percentile:       {summary['response_times']['p99']:.3f}s")

        print("\n--- STATUS CODES ---")
        for code, count in sorted(summary['status_codes'].items()):
            print(f"{code}:                     {count}")

        print("\n--- ENDPOINT BREAKDOWN ---")
        for endpoint, metrics in summary['endpoint_metrics'].items():
            avg_time = statistics.mean(metrics['response_times']) if metrics['response_times'] else 0
            success_rate = (metrics['success'] / metrics['count'] * 100) if metrics['count'] > 0 else 0
            print(f"\n{endpoint}")
            print(f"  Requests:            {metrics['count']}")
            print(f"  Success Rate:        {success_rate:.2f}%")
            print(f"  Avg Response Time:   {avg_time:.3f}s")

        if summary['errors']:
            print("\n--- SAMPLE ERRORS ---")
            for endpoint, error in summary['errors'][:5]:
                print(f"{endpoint}: {error}")

        print("=" * 80)


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Load testing tool for Flask application',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  USER MODE (Concurrent users making N requests each):
    # Light load test
    python load_test.py https://class15.akhileshmishra.tech -u 10 -r 20

    # Medium load test
    python load_test.py https://class15.akhileshmishra.tech -u 50 -r 50 --ramp-up 10

    # Heavy load test
    python load_test.py https://class15.akhileshmishra.tech -u 100 -r 100 --ramp-up 20

  RPS MODE (Sustain specific requests per second):
    # 10 requests per second for 60 seconds
    python load_test.py https://class15.akhileshmishra.tech --rps 10 --duration 60

    # 50 requests per second for 2 minutes
    python load_test.py https://class15.akhileshmishra.tech --rps 50 --duration 120

    # 100 requests per second for 5 minutes
    python load_test.py https://class15.akhileshmishra.tech --rps 100 --duration 300

  RPM MODE (Requests per minute):
    # 600 requests per minute (10 RPS) for 60 seconds
    python load_test.py https://class15.akhileshmishra.tech --rpm 600 --duration 60

    # 3000 requests per minute (50 RPS) for 2 minutes
    python load_test.py https://class15.akhileshmishra.tech --rpm 3000 --duration 120
        """
    )

    parser.add_argument('url', help='Base URL of the application (e.g., https://class15.akhileshmishra.tech)')

    # User mode arguments
    parser.add_argument('-u', '--users', type=int, default=10,
                       help='Number of concurrent users/workers (default: 10)')
    parser.add_argument('-r', '--requests', type=int, default=10,
                       help='Requests per user in user mode (default: 10)')
    parser.add_argument('--ramp-up', type=int, default=0,
                       help='Ramp-up time in seconds for user mode (default: 0)')

    # RPS mode arguments
    parser.add_argument('--rps', type=float,
                       help='Requests per second (enables RPS mode, requires --duration)')
    parser.add_argument('--rpm', type=float,
                       help='Requests per minute (enables RPS mode, requires --duration)')
    parser.add_argument('--duration', type=int,
                       help='Test duration in seconds (required for RPS/RPM mode)')

    args = parser.parse_args()

    # Validate arguments
    if args.rpm and args.rps:
        parser.error("Cannot specify both --rps and --rpm")

    rps = args.rps
    if args.rpm:
        rps = args.rpm / 60.0  # Convert RPM to RPS

    if rps is not None and args.duration is None:
        parser.error("--duration is required when using --rps or --rpm")

    if rps is None and args.duration is not None:
        parser.error("--rps or --rpm is required when using --duration")

    tester = LoadTester(
        base_url=args.url,
        concurrent_users=args.users,
        requests_per_user=args.requests,
        ramp_up_time=args.ramp_up,
        rps=rps,
        duration=args.duration
    )

    tester.run()


if __name__ == '__main__':
    main()
