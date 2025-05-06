from django.contrib import admin
from django.urls import path, include
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.views import obtain_auth_token
from django.conf import settings
from django.conf.urls.static import static

schema_view = get_schema_view(
    openapi.Info(
        title="Task Processing API",
        default_version='v1',
        description="API for processing background tasks",
    ),
    public=True,
    permission_classes=[AllowAny],
)

schema_view.swagger_ui_config = {
    'securityDefinitions': {
        'TokenAuth': {
            'type': 'apiKey',
            'in': 'header',
            'name': 'Authorization',
            'description': 'Enter token as: Token <your_token_here>',
        }
    },
    'security': [
        {'TokenAuth': []}
    ]
}

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('tasks.urls')),
    path('api-token-auth/', obtain_auth_token, name='api_token_auth'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('accounts/', include('django.contrib.auth.urls')),  # Add authentication URLs
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
