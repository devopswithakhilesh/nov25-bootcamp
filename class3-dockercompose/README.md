To run the app, run postgres db first -> use below command



docker run --name some-postgres \ 
-e POSTGRES_USER=postgres
-e POSTGRES_PASSWORD=postgres \
-e POSTGRES_DB=flask_blog
 -d postgres


# Flask Blog Application

A simple blog application built with Flask, PostgreSQL, and SQLAlchemy. Features include creating and reading blog posts with a clean, responsive UI.

## Features

- Create new blog posts
- View all posts in a grid layout
- View individual posts
- Responsive design
- PostgreSQL database integration
- Docker support for easy deployment

## Tech Stack

- **Backend**: Flask, SQLAlchemy
- **Database**: PostgreSQL
- **Frontend**: HTML, CSS
- **Containerization**: Docker, Docker Compose

## Project Structure

```
.
├── app.py                  # Main Flask application
├── requirements.txt        # Python dependencies
├── Dockerfile             # Docker configuration
├── docker-compose.yml     # Docker Compose configuration
├── templates/             # HTML templates
│   ├── base.html         # Base template
│   ├── index.html        # Home page (list posts)
│   ├── create.html       # Create post page
│   └── view_post.html    # View single post
└── static/
    └── css/
        └── style.css     # CSS styling
```

## Running with Docker (Recommended)

1. Make sure you have Docker and Docker Compose installed

2. Start the application:
```bash
docker-compose up --build
```

3. Access the application at `http://localhost:5000`

4. To stop the application:
```bash
docker-compose down
```

## Running Locally (Without Docker)

1. Install PostgreSQL and create a database:
```bash
createdb flask_blog
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Set environment variables (optional):
```bash
export DATABASE_URL="postgresql://{username}:{password}@{dbhost}:5432/{db_name}"
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/flask_blog"
export SECRET_KEY="your-secret-key"
```

4. Run the application:
```bash
python app.py
```

5. Access the application at `http://localhost:5000`

## Environment Variables

- `DATABASE_URL`: PostgreSQL connection string (default: `postgresql://postgres:postgres@localhost:5432/flask_blog`)
- `SECRET_KEY`: Flask secret key for sessions (default: `dev-secret-key-change-in-production`)

## Usage

1. **Home Page**: View all blog posts in a card layout
2. **Create Post**: Click "Create Post" in the navigation to add a new post
3. **View Post**: Click on any post title or "Read More" to view the full post

## Database Schema

### Post Model
- `id`: Primary key (Integer)
- `title`: Post title (String, max 200 characters)
- `content`: Post content (Text)
- `created_at`: Timestamp (DateTime)

## Development

To make changes to the application:

1. Edit the files locally
2. Rebuild the Docker containers:
```bash
docker-compose up --build
```

Or if running locally, just restart the Flask app.

## Notes

- The database tables are created automatically on first run
- Flash messages provide feedback for user actions
- The application uses SQLAlchemy ORM for database operations
- Responsive design works on mobile and desktop devices



========