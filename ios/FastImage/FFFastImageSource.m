#import "FFFastImageSource.h"

#import <SDWebImage/SDWebImageDownloader.h>

/**
 * Headers keyed by the absolute URL string they were supplied for.
 * Guarded by @synchronized on the dictionary itself.
 */
static NSMutableDictionary *FFFHeadersByURL(void) {
    static NSMutableDictionary *registry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registry = [NSMutableDictionary dictionary];
    });
    return registry;
}

@implementation FFFastImageSource

- (instancetype)initWithURL:(NSURL *)url
                   priority:(FFFPriority)priority
                    headers:(NSDictionary *)headers
{
    self = [super init];
    if (self) {
        _uri = url;
        _priority = priority;
        _headers = headers;
    }
    return self;
}

+ (void)registerHeaders:(NSDictionary *)headers forURL:(NSURL *)url
{
    NSString *key = url.absoluteString;
    if (key.length == 0) {
        return;
    }

    NSMutableDictionary *registry = FFFHeadersByURL();
    @synchronized (registry) {
        if (headers.count > 0) {
            registry[key] = [headers copy];
        } else {
            // Nothing to send for this URL. Drop any earlier entry so a source
            // without headers can never inherit a previous source's credentials.
            [registry removeObjectForKey:key];
        }
    }

    [self installHeadersFilter];
}

+ (NSDictionary *)registeredHeadersForURL:(NSURL *)url
{
    NSString *key = url.absoluteString;
    if (key.length == 0) {
        return nil;
    }

    NSMutableDictionary *registry = FFFHeadersByURL();
    @synchronized (registry) {
        return registry[key];
    }
}

/**
 * Install the filter that scopes registered headers to their own request.
 * SDWebImage invokes it once per download, passing the downloader's default
 * headers; whatever we return becomes the headers for that request.
 */
+ (void)installHeadersFilter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
        // Preserve a filter the host app may already have installed.
        SDWebImageDownloaderHeadersFilterBlock previousFilter = downloader.headersFilter;

        downloader.headersFilter = ^SDHTTPHeadersDictionary * _Nullable (NSURL * _Nullable url,
                                                                        SDHTTPHeadersDictionary * _Nullable headers) {
            SDHTTPHeadersDictionary *base = previousFilter ? previousFilter(url, headers) : headers;
            NSDictionary *scoped = [FFFastImageSource registeredHeadersForURL:url];
            if (scoped.count == 0) {
                return base;
            }

            SDHTTPHeadersMutableDictionary *merged = base ? [base mutableCopy] : [NSMutableDictionary dictionary];
            [merged addEntriesFromDictionary:scoped];
            return [merged copy];
        };
    });
}

@end
