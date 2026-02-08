from models import Post


def test_home_page_returns_200(client):
    response = client.get('/')
    assert response.status_code == 200


def test_home_page_contains_html(client):
    response = client.get('/')
    assert b'<!DOCTYPE html>' in response.data or b'<html' in response.data


def test_create_post(client, db):
    response = client.post('/create', data={
        'title': 'Test Post',
        'content': 'This is test content'
    }, follow_redirects=True)
    assert response.status_code == 200
    post = Post.query.filter_by(title='Test Post').first()
    assert post is not None
    assert post.content == 'This is test content'


def test_view_single_post(client, db):
    post = Post(title='View Test', content='View content')
    db.session.add(post)
    db.session.commit()

    response = client.get(f'/post/{post.id}')
    assert response.status_code == 200
    assert b'View Test' in response.data


def test_post_not_found_returns_404(client):
    response = client.get('/post/9999')
    assert response.status_code == 404


def test_celery_page_returns_200(client):
    response = client.get('/celery')
    assert response.status_code == 200
