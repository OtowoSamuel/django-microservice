class ForwardedHostMiddleware:
    """
    Middleware that sets the Host header for Django based on AWS ELB or other proxies.
    This will fix 400 Bad Request errors that happen when the Host header doesn't match ALLOWED_HOSTS.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Print debug info to logs
        host = request.META.get('HTTP_HOST', '')
        original_host = host
        
        # Common headers to check for proxied requests
        forwarded_host = request.META.get('HTTP_X_FORWARDED_HOST')
        forwarded_server = request.META.get('HTTP_X_FORWARDED_SERVER')
        forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        
        # Log what we received
        print(f"DEBUG: Original Host: {original_host}", flush=True)
        print(f"DEBUG: X-Forwarded-Host: {forwarded_host}", flush=True)
        print(f"DEBUG: X-Forwarded-Server: {forwarded_server}", flush=True) 
        print(f"DEBUG: X-Forwarded-For: {forwarded_for}", flush=True)
        
        # If we have a forwarded host header, use it
        if forwarded_host:
            request.META['HTTP_HOST'] = forwarded_host
            print(f"DEBUG: Using X-Forwarded-Host: {forwarded_host}", flush=True)
        # Try the ELB's forwarded server header
        elif forwarded_server:
            request.META['HTTP_HOST'] = forwarded_server
            print(f"DEBUG: Using X-Forwarded-Server: {forwarded_server}", flush=True)
        # If all else fails and we have a load balancer hostname/IP, use it
        elif 'elb.amazonaws.com' in host:
            # We already have the ELB hostname, so don't change it
            pass
        # Fall back to a safe default that will always be in ALLOWED_HOSTS
        elif host == '':
            request.META['HTTP_HOST'] = 'localhost'
            print(f"DEBUG: Empty host, setting to localhost", flush=True)

        # Print final host header
        print(f"DEBUG: Final Host header: {request.META.get('HTTP_HOST')}", flush=True)
        
        # Continue with the request
        return self.get_response(request)