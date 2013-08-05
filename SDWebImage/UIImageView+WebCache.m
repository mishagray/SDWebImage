/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation UIImageView (WebCache)

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock
{
    [self cancelCurrentImageLoad];

    self.image = placeholder;
    
    if (url)
    {
        __weak UIImageView *wself = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
        {
            if (!wself) return;
            void (^block)(void) = ^
            {
                __strong UIImageView *sself = wself;
                if (!sself) return;
                if (image)
                {
                    sself.image = image;
                    [sself setNeedsLayout];
                }
                if (completedBlock && finished)
                {
                    completedBlock(image, error, cacheType);
                }
            };
            if ([NSThread isMainThread])
            {
                block();
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), block);
            }
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setBestImageFromCacheWithUrls:(NSArray *)urls
                     placeholderImage:(UIImage *)placeholder
                                 done:(void (^)(UIImage *image, SDImageCacheType cacheType))doneBlock
{
    [self cancelCurrentImageLoad];
    
    SDWebImageManager * manager = SDWebImageManager.sharedManager;
    
    NSMutableArray * keysArray = [NSMutableArray arrayWithCapacity:urls];
    
    [urls enumerateObjectsUsingBlock:^(NSURL * url, NSUInteger idx, BOOL *stop) {
        if ([url isKindOfClass:NSString.class])
        {
            url = [NSURL URLWithString:(NSString *)url];
        }
        NSString * key = [manager cacheKeyForURL:url];
        [keysArray addObject:key];
    }];
    
    [manager.imageCache queryDiskCacheForBestImageInKeyArray:keysArray
                                                    onMemory:^BOOL(UIImage *image) {
                                                        if (image != nil) {
                                                            self.image = image;
                                                        }
                                                        else {
                                                            self.image = placeholder;
                                                        }
                                                        return TRUE;
                                                    }
                                                    done:^(UIImage *image, SDImageCacheType cacheType) {
                                                        if (image != nil) {
                                                            self.image = image;
                                                        }
                                                        if (doneBlock) {
                                                            doneBlock(image,cacheType);
                                                        }
                                                    }];
    
}


- (void)cancelCurrentImageLoad
{
    // Cancel in progress downloader from queue
    id<SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
