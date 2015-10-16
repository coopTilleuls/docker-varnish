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
backend nytco {
	# todo define back-end host
	.host = "nginx";
	.port = "8080";
}

# Define an access control list to restrict cache purging.
acl purge {
	"192.168.33.1"/8;
}

sub vcl_recv {
	# todo define host name
	#if (req.http.host == "{{environment-specific-hostname}}") {
	#	set req.backend_hint = nytco;
	#}
	# Fall-through for admin interface requests
	if (req.url~ "^/wp-admin/") {
		return (pass);
	}

	# Purge the cache if the client is allowed to.
	if (req.method == "PURGE") {
		if (!client.ip ~ purge) {
			return(synth(405,"Not allowed."));
		}
		return (purge);
	}

	set req.http.host = "dev.nytco.com";
	# Remove querystrings.
	set req.url = querystring.remove(req.url);

	# Ignore all cookies.
	unset req.http.cookie;
}

sub vcl_backend_response {
	# Happens after we have read the response headers from the backend.
	#
	# Here you clean the response headers, removing silly Set-Cookie headers
	# and other mistakes your backend does.
}

sub vcl_deliver {
	# Fall-through for dev that doesn't work right now. Prob need to do something with beresp too.
	set resp.http.age = "0";

	# Happens when we have all the pieces we need, and are about to send the
	# response to the client.
	#
	# You can do accounting or modifying the final object here.
}