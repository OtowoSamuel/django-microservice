from django.contrib import admin
from django.urls import path, include
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.views import obtain_auth_token
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse

def index(request):
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Django Microservice API</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
            h1 { color: #333; }
            .button { display: inline-block; background-color: #4CAF50; color: white; padding: 10px 20px; 
                     text-align: center; text-decoration: none; font-size: 16px; margin: 10px 5px; 
                     cursor: pointer; border-radius: 5px; }
            .info { background-color: #f9f9f9; border-left: 6px solid #2196F3; padding: 10px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <h1>Django Microservice API</h1>
        
        <p>Welcome to the Django Microservice API. This application demonstrates a microservice architecture with Django, Celery, Redis, and Kubernetes.</p>
        
        <div class="info">
            <h3>Authentication Required</h3>
            <p>This API requires token authentication. Use the following token for testing:</p>
            <code>Token a2646fef3ce417ecba425253834db1313d2d463a</code>
        </div>
        
        <h2>Available Endpoints</h2>
        
        <p>
            <a class="button" href="/swagger/">API Documentation (Swagger UI)</a>
            <a class="button" href="/api/">API Endpoints</a>
            <a class="button" href="/admin/">Admin Interface</a>
        </p>
        
        <h2>How to Use the API</h2>
        
        <p>To use this API:</p>
        <ol>
            <li>Visit the <a href="/swagger/">Swagger UI</a> to explore available endpoints</li>
            <li>Click the "Authorize" button and enter <code>Token a2646fef3ce417ecba425253834db1313d2d463a</code></li>
            <li>Test the API endpoints directly from the Swagger UI interface</li>
        </ol>
        
        <hr>
        <footer>
            <p><small>Django Microservice Assessment - Deployed on AWS EKS</small></p>
        </footer>
    </body>
    </html>
    """
    return HttpResponse(html_content)

schema_view = get_schema_view(
    openapi.Info(
        title="Task Processing API",
        default_version='v1',
        description="API for processing background tasks",
    ),
    public=True,
    permission_classes=[AllowAny],
)

urlpatterns = [
    path('', index, name='index'),  # Using direct function view instead of template
    path('admin/', admin.site.urls),
    path('api/', include('tasks.urls')),
    path('api-token-auth/', obtain_auth_token, name='api_token_auth'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('accounts/', include('django.contrib.auth.urls')),  # Add authentication URLs
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
