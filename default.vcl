# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# https://github.com/Dridi/libvmod-querystring
import querystring;

# Default backend definition. Set this to point to your content server.
backend www {
	.host = "127.0.0.1";
	.port = "8080";
}

# Define an access control list to restrict cache purging.
acl purge {
	"127.0.0.1";
	"192.168.0.0"/16;
}

sub vcl_recv {

	# https://github.com/mattiasgeniar/varnish-4.0-configuration-templates/blob/master/default.vcl
	if (req.method == "PURGE") {
		if (!client.ip ~ purge) {
			return(synth(405, "Not allowed."));
		}
		return (purge);
	}

  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PATCH" &&
      req.method != "DELETE") {
    return (pipe);
  }

  # Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
  if (req.http.Upgrade ~ "(?i)websocket") {
    return (pipe);
  }

  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

  if (req.http.Authorization) {
    return (pass);
  }

	if (req.url~ "^/wp-admin/") {
		return (pass);
	}


	####

  if (req.url ~ "\#") {
    set req.url = regsub(req.url, "\#.*$", "");
  }

  if (req.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|pdf|png|rtf|swf|txt|woff|xml)(\?.*)?$") {
    unset req.http.Cookie;
    set req.url = querystring.remove(req.url);
    return (hash);
  }

	set req.url = querystring.clean(req.url);

  if (req.url ~ "\?") {
    set req.url = querystring.sort(req.url);
  }

  return (hash);
}

sub vcl_hash {

  hash_data(req.url);
  
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }
  
  if (req.http.origin) {
  	hash_data(req.http.origin);
  }
  
  return (lookup);
}

sub vcl_backend_response {
	# Happens after we have read the response headers from the backend.
	#
	# Here you clean the response headers, removing silly Set-Cookie headers
	# and other mistakes your backend does.
}

sub vcl_deliver {
	# Fall-through for dev that doesn't work right now. Prob need to do something with beresp too.
	# Happens when we have all the pieces we need, and are about to send the
	# response to the client.
	#
	# You can do accounting or modifying the final object here.
}