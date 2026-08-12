#import "FFFastImageView.h"

@implementation FFFastImageView {
    BOOL hasSentOnLoadStart;
    BOOL hasCompleted;
    BOOL hasErrored;
    NSDictionary* onLoadEvent;
}

- (id) init {
    self = [super init];
    self.resizeMode = RCTResizeModeCover;
    self.clipsToBounds = YES;
    return self;
}

- (void)setResizeMode:(RCTResizeMode)resizeMode
{
    if (_resizeMode != resizeMode) {
        _resizeMode = resizeMode;
        self.contentMode = (UIViewContentMode)resizeMode;
    }
}

- (void)setOnFastImageLoadEnd:(RCTBubblingEventBlock)onFastImageLoadEnd {
    _onFastImageLoadEnd = onFastImageLoadEnd;
    if (hasCompleted) {
        _onFastImageLoadEnd(@{});
    }
}

- (void)setOnFastImageLoad:(RCTBubblingEventBlock)onFastImageLoad {
    _onFastImageLoad = onFastImageLoad;
    if (hasCompleted) {
        _onFastImageLoad(onLoadEvent);
    }
}

- (void)setOnFastImageError:(RCTDirectEventBlock)onFastImageError {
    _onFastImageError = onFastImageError;
    if (hasErrored) {
        _onFastImageError(@{});
    }
}

- (void)setOnFastImageLoadStart:(RCTBubblingEventBlock)onFastImageLoadStart {
    if (_source && !hasSentOnLoadStart) {
        _onFastImageLoadStart = onFastImageLoadStart;
        onFastImageLoadStart(@{});
        hasSentOnLoadStart = YES;
    } else {
        _onFastImageLoadStart = onFastImageLoadStart;
        hasSentOnLoadStart = NO;
    }
}

- (void)setSource:(FFFastImageSource *)source {
    if (_source != source) {
        _source = source;
        
        // Set headers, scoped to this URL only. Writing them onto the shared
        // downloader would attach them to every later image request (CVE-2020-7696).
        [FFFastImageSource registerHeaders:_source.headers forURL:_source.uri];
        
        // Set priority.
        SDWebImageOptions options = 0;
        options |= SDWebImageRetryFailed;
        switch (_source.priority) {
            case FFFPriorityLow:
                options |= SDWebImageLowPriority;
                break;
            case FFFPriorityNormal:
                // Priority is normal by default.
                break;
            case FFFPriorityHigh:
                options |= SDWebImageHighPriority;
                break;
        }
        
        if (_onFastImageLoadStart) {
            _onFastImageLoadStart(@{});
            hasSentOnLoadStart = YES;
        } {
            hasSentOnLoadStart = NO;
        }
        hasCompleted = NO;
        hasErrored = NO;
        
        // Load the new source.
        [self sd_setImageWithURL:_source.uri
                placeholderImage:nil
                         options:options
                        progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                            if (_onFastImageProgress) {
                                _onFastImageProgress(@{
                                                       @"loaded": @(receivedSize),
                                                       @"total": @(expectedSize)
                                                       });
                            }
                        } completed:^(UIImage * _Nullable image,
                                      NSError * _Nullable error,
                                      SDImageCacheType cacheType,
                                      NSURL * _Nullable imageURL) {
                            if (error) {
                                hasErrored = YES;
                                if (_onFastImageError) {
                                    _onFastImageError(@{});
                                }
                                if (_onFastImageLoadEnd) {
                                    _onFastImageLoadEnd(@{});
                                }
                            } else {
                                hasCompleted = YES;
                                onLoadEvent = @{
                                                @"width":[NSNumber numberWithDouble:image.size.width],
                                                @"height":[NSNumber numberWithDouble:image.size.height]
                                                };
                                if (_onFastImageLoad) {
                                    _onFastImageLoad(onLoadEvent);
                                }
                                if (_onFastImageLoadEnd) {
                                    _onFastImageLoadEnd(@{});
                                }
                            }
                        }];
    }
}

@end

