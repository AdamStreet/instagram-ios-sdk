//
//  InstagramMetaDataKeys.h
//  PhotoBomb
//
//  Created by Adam Szabo on 1/1/14.
//  Copyright (c) 2014 Soft-Constructor Kft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InstagramMetaDataKeys : NSObject

// Pagination
extern NSString * const kInstagramMetaDataPaginationKey;
extern NSString * const kInstagramMetaDataPaginationNextUrlKey;
extern NSString * const kInstagramMetaDataPaginationNextMaxIdKey;

// Meta/code
extern NSString * const kInstagramMetaDataMetaKey;
extern NSString * const kInstagramMetaDataMetaCodeKey;

// Data
extern NSString * const kInstagramMetaDataDataKey;
extern NSString * const kInstagramMetaDataDataAttributionKey;
extern NSString * const kInstagramMetaDataDataTagsKey;
extern NSString * const kInstagramMetaDataDataTypeKey;
//extern NSString * const kInstagramMetaDataDataLocationKey;

extern NSString * const kInstagramMetaDataDataCommentsKey;
extern NSString * const kInstagramMetaDataDataCommentsCountKey;
//extern NSString * const kInstagramMetaDataDataCommentsDataKey;

extern NSString * const kInstagramMetaDataDataFilterKey;
extern NSString * const kInstagramMetaDataDataCreatedTimeKey;
extern NSString * const kInstagramMetaDataDataLinkKey;

extern NSString * const kInstagramMetaDataDataLikesKey;
extern NSString * const kInstagramMetaDataDataLikesCountKey;
//extern NSString * const kInstagramMetaDataDataLikesDataKey;
extern NSString * const kInstagramMetaDataDataImagesKey;
extern NSString * const kInstagramMetaDataDataImagesLowResolutionKey;
extern NSString * const kInstagramMetaDataDataImagesThumbnailKey;
extern NSString * const kInstagramMetaDataDataImagesStandardResolutionKey;
extern NSString * const kInstagramMetaDataDataImagesUrlKey;
extern NSString * const kInstagramMetaDataDataImagesWidthKey;
extern NSString * const kInstagramMetaDataDataImagesHeightKey;
//extern NSString * const kInstagramMetaDataDataUsersInPhotoKey;
//extern NSString * const kInstagramMetaDataDataCaptionKey;
extern NSString * const kInstagramMetaDataDataUserHasLikedKey;
extern NSString * const kInstagramMetaDataDataIdKey;

extern NSString * const kInstagramMetaDataDataUserKey;
extern NSString * const kInstagramMetaDataDataUserUserNameKey;
extern NSString * const kInstagramMetaDataDataUserProfilePictureUrlKey;
extern NSString * const kInstagramMetaDataDataUserFullNameKey;
extern NSString * const kInstagramMetaDataDataUserIdKey;

@end
