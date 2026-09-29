import 'dart:io';

/// One hop in a redirect chain.
class RedirectHop {
  const RedirectHop({required this.url, required this.status});

  final String url;
  final int status;
}

class LinkRevealResult {
  const LinkRevealResult({
    required this.hops,
    required this.finalUrl,
    this.error,
  });

  final List<RedirectHop> hops;
  final String finalUrl;
  final String? error;

  bool get redirected => hops.length > 1;
}

/// Follows a shortened link's redirects with HEAD requests and reports where
/// it ends up, without loading any page content.
///
/// Only the redirect hops are contacted, with no cookies and a generic
/// user-agent. The user is warned before this runs, because the shortener
/// (and therefore whoever made the link) can see that it was resolved.
class LinkReveal {
  const LinkReveal();

  static const _maxHops = 8;

  Future<LinkRevealResult> reveal(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..userAgent = 'Mozilla/5.0 (Linux; Android) JemixoSafe/1.1';
    final hops = <RedirectHop>[];
    var current = url;
    try {
      for (var i = 0; i < _maxHops; i++) {
        final uri = Uri.tryParse(current);
        if (uri == null || !uri.hasScheme) {
          return LinkRevealResult(hops: hops, finalUrl: current, error: 'Not a valid address');
        }
        HttpClientResponse response;
        try {
          final request = await client.headUrl(uri);
          request.followRedirects = false;
          response = await request.close().timeout(const Duration(seconds: 10));
        } on HttpException {
          // Some hosts reject HEAD; retry with GET but drop the body.
          final request = await client.getUrl(uri);
          request.followRedirects = false;
          response = await request.close().timeout(const Duration(seconds: 10));
        }
        hops.add(RedirectHop(url: current, status: response.statusCode));
        await response.drain<void>();
        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || location.isEmpty) break;
          current = uri.resolve(location).toString();
          continue;
        }
        break;
      }
      return LinkRevealResult(hops: hops, finalUrl: current);
    } catch (error) {
      return LinkRevealResult(
        hops: hops,
        finalUrl: current,
        error: 'Could not resolve the link: ${error.runtimeType}',
      );
    } finally {
      client.close(force: true);
    }
  }
}
