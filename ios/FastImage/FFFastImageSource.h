#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FFFPriority) {
    FFFPriorityLow,
    FFFPriorityNormal,
    FFFPriorityHigh
};

/**
 * Object containing an image URL and associated metadata.
 */
@interface FFFastImageSource : NSObject

@property (nonatomic) NSURL* uri;
@property (nonatomic) FFFPriority priority;
@property (nonatomic) NSDictionary *headers;

- (instancetype)initWithURL:(NSURL *)url
                   priority:(FFFPriority)priority
                    headers:(NSDictionary *)headers;

/**
 * Record the headers that belong to a single image URL.
 *
 * SDWebImage 4.x has no per-request context, so headers used to be written onto
 * `[SDWebImageDownloader sharedDownloader]` with `setValue:forHTTPHeaderField:`.
 * Those headers are global and sticky, so credentials supplied for one image were
 * attached to every later image request in the process, including requests to
 * third-party hosts (CVE-2020-7696).
 *
 * Headers registered here are applied to their own URL only, via a `headersFilter`
 * installed on the shared downloader. Passing nil or an empty dictionary clears any
 * headers previously registered for `url`.
 */
+ (void)registerHeaders:(NSDictionary *)headers forURL:(NSURL *)url;

@end
