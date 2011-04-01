//
//  ENAPIPostRequest.m
//  libechonest
//
//  Created by Art Gillespie on 3/15/11. art@tapsquare.com
//

#import "ENAPIPostRequest.h"
#import "asi-http-request/ASIFormDataRequest.h"
#import "asi-http-request/ASIProgressDelegate.h"
#import "ENAPI.h"
#import "ENAPI_utils.h"
#import "ENAPIPostRequest.h"
#import "NSObject+JSON.h"

@interface ENAPIPostRequest() 
@property (retain) ASIFormDataRequest *request;
@property (retain) NSDictionary *_responseDict;
@end

@implementation ENAPIPostRequest
@synthesize delegate, request, _responseDict;


- (id)initWithURL:(NSURL *)url {
    
    self = [super init];
    if (self) {
        self.request = [ASIFormDataRequest requestWithURL:url];
        self.request.postFormat = ASIMultipartFormDataPostFormat;
        [self.request setPostValue:[ENAPI apiKey] forKey:@"api_key"];
        self.request.delegate = self;
        self.request.uploadProgressDelegate = self;
        self.request.timeOutSeconds = 180;
    }
    return self;
}

- (void)setPostValue:(NSObject *)value forKey:(NSString *)key {
    [self.request setPostValue:value forKey:key];
}

- (void)setFile:(NSString *)path forKey:(NSString *)key {
    [self.request setFile:path forKey:key];
}

- (void)startSynchronous {
    [self retain]; // let's make sure we're still around when the network call returns
    [self.request startSynchronous];
}

- (void)startAsynchronous {
    [self retain]; // let's make sure we're still around when the network call returns
    [self.request startAsynchronous];
}

+ (ENAPIPostRequest *)requestWithURL:(NSURL *)url {
    return [[[ENAPIPostRequest alloc] initWithURL:url] autorelease];
    
}

+ (ENAPIPostRequest *)trackUploadRequestWithFile:(NSString *)filePath {
    CHECK_API_KEY
    NSString *urlString = [NSString stringWithFormat:@"%@track/upload", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setFile:filePath forKey:@"track"];
    [postRequest setPostValue:@"mp3" forKey:@"filetype"];
    return postRequest;
}

+ (ENAPIPostRequest *)trackAnalyzeRequestWithFile:(NSString *)filePath {
    CHECK_API_KEY
    // we need the md5 of the file
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    NSString *md5 = [fileData MD5];
    return [ENAPIPostRequest trackAnalyzeRequestWithMD5:md5];
}

+ (ENAPIPostRequest *)trackAnalyzeRequestWithId:(NSString *)trackid {
    CHECK_API_KEY
    NSString *urlString = [NSString stringWithFormat:@"%@track/analyze", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
        
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setPostValue:trackid forKey:@"id"];
    return postRequest;    
}

+ (ENAPIPostRequest *)trackAnalyzeRequestWithMD5:(NSString *)md5 {
    CHECK_API_KEY
    NSString *urlString = [NSString stringWithFormat:@"%@track/analyze", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setPostValue:md5 forKey:@"md5"];
    return postRequest;    
}

+ (ENAPIPostRequest *)catalogCreateWithName:(NSString *)name type:(NSString *)type {
    NSString *urlString = [NSString stringWithFormat:@"%@catalog/create", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setPostValue:name forKey:@"name"];
    [postRequest setPostValue:type forKey:@"type"];
    return postRequest;    
}

+ (ENAPIPostRequest *)catalogDeleteWithID:(NSString *)ID {
    NSString *urlString = [NSString stringWithFormat:@"%@catalog/delete", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setPostValue:ID forKey:@"id"];
    return postRequest;        
}

+ (ENAPIPostRequest *)catalogUpdateWithID:(NSString *)ID data:(NSString *)json {
    NSString *urlString = [NSString stringWithFormat:@"%@catalog/update", ECHONEST_API_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ENAPIPostRequest *postRequest = [ENAPIPostRequest requestWithURL:url];
    [postRequest setPostValue:ID forKey:@"id"];
    [postRequest setPostValue:json forKey:@"data"];
    [postRequest setPostValue:@"json" forKey:@"json"];
    return postRequest;            
}

#pragma mark - ASIProgressDelegate

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    if ([self.delegate respondsToSelector:@selector(request:progress:)]) {
        [(id<ENAPIPostRequestDelegate>)self.delegate request:self progress:bytes];
    }
}

#pragma mark - ASIRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    if ([self.delegate respondsToSelector:@selector(requestFinished:)]) {
        [(id<ENAPIPostRequestDelegate>)self.delegate requestFinished:self];
    }
    [self release];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    if ([self.delegate respondsToSelector:@selector(requestFailed:)]) {
        [(id<ENAPIPostRequestDelegate>)self.delegate requestFailed:self];
    }
    [self release];
}


#pragma mark - Properties

- (NSDictionary *)response {
    if (nil == _responseDict) {
        NSDictionary *dict = [self.request.responseString JSONValue];
        _responseDict = [dict retain];
    }
    return _responseDict;
}

- (NSUInteger)responseStatusCode {
    return self.request.responseStatusCode;
}

- (NSError *)error {
    return self.request.error;
}

- (NSUInteger)echonestStatusCode {
    return [[self.response valueForKeyPath:@"response.status.code"] intValue];
}

- (NSString *)echonestStatusMessage {
    return [self.response valueForKeyPath:@"response.status.message"];
}

- (void) dealloc {
    delegate = nil;
    [request release];
    [_responseDict release];
    [super dealloc];
}
@end
