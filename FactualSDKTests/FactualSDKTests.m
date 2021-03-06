//
//  FactualSDKTests.m
//  FactualSDKTests
//
//  Created by Brandon Yoshimoto on 7/16/12.
//  Copyright (c) 2012 Factual. All rights reserved.
//

#import "FactualSDKTests.h"
#import <FactualSDK/FactualAPI.h>
#import "FactualQueryImpl.h"
#import "FactualRowMetadata.h"
#import "FactualAPI.h"
#import <CoreLocation/CLLocation.h>

@implementation FactualSDKTests

FactualAPI* _apiObject;
BOOL _finished;
FactualQueryResult* _queryResult;
NSDictionary* _rawResult;
NSString* _matchResult;

double _latitude;
double _longitude;
double _meters;

// Add your key and secret
NSString* _key = @"";
NSString* _secret = @"";

- (void)setUp
{
    [super setUp];
    _latitude = 34.06018;
    _longitude = -118.41835;
    _meters = 5000;
    
    _finished = false;
    
    _queryResult = nil;
    _rawResult = nil;
    _matchResult = nil;
    _apiObject = [[FactualAPI alloc] initWithAPIKey:_key secret:_secret];
}

- (void)tearDown
{
    [super tearDown];
    
    _finished = false;
    
    _queryResult = nil;
    _rawResult = nil;
    _matchResult = nil;
}

- (void)testCoreExample1
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"country"
                                                  equalTo:@"US"]];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    STAssertTrue(_queryResult.totalRows == -1, @"Invalid total rows");
}

- (void)testCoreExample2
{
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"name"
                                               beginsWith:@"Star"]];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid response");
    
}

- (void)testCoreExample3
{
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addFullTextQueryTerm:@"Fried Chicken, Los Angeles"];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testCoreExample4
{
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addFullTextQueryTerm:@"Fried Chicken, Los Angeles"];
    queryObject.offset = 20;
    queryObject.limit = 5;
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertEquals(5U, [_queryResult.rows count], @"Not equal");
}


- (void)testFacet
{
    FactualQuery* query = [FactualQuery query];
    query.maxValuesPerFacet = 20;
    query.minCountPerFacetValue = 100;
    
    [query addRowFilter:[FactualRowFilter fieldName:@"country"
                                            equalTo:@"US"]];
    [query addSelectTerm:@"region"];
    [query addSelectTerm:@"locality"];
    [query addFullTextQueryTerm:@"Starbucks"];
    query.includeRowCount = true;
    
    [_apiObject facetTable:@"places" optionalQueryParams:query withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    STAssertTrue(_queryResult.totalRows > 0, @"Invalid total rows");
    
}

- (void)testCoreExample5
{
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"name"
                                                  equalTo:@"Apple Store"]];
    
    CLLocationCoordinate2D coordinate = {_latitude, _longitude};
    [queryObject setGeoFilter:coordinate 
               radiusInMeters:_meters];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testSort_byDistance
{
    FactualQuery* queryObject = [FactualQuery query];
    
    CLLocationCoordinate2D coordinate = {_latitude, _longitude};
    [queryObject setGeoFilter:coordinate 
               radiusInMeters:_meters];
    
    FactualSortCriteria* primarySort = [[FactualSortCriteria alloc] initWithFieldName:@"$distance" sortOrder:FactualSortOrder_Ascending];
    [queryObject setPrimarySortCriteria:primarySort];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testRowFilters_2beginsWith
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"name"
                                               beginsWith:@"McDonald's"]];
    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"category"
                                               beginsWith:@"Food & Beverage"]];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testIn
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"region"
                                                       In:@"CA",@"NM",@"FL",nil]];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testComplicated
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"region"
                                                       In:@"MA",@"VT",@"NH",nil]];
    [queryObject addRowFilter:[FactualRowFilter orFilter:[FactualRowFilter fieldName:@"name"
                                                                          beginsWith:@"Coffee"]
                               ,[FactualRowFilter fieldName:@"name"
                                                 beginsWith:@"Star"], nil]];
    
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testSimpleTel
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"tel"
                                               beginsWith:@"(212)"]];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testFullTextSearch_on_a_field
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"name"
                                                   search:@"Fried Chicken"]];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testCrosswalk_ex1
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"factual_id"
                                                  equalTo:@"860fed91-3a52-44c8-af7b-8095eb943da1"]];    
    
    [_apiObject queryTable:@"crosswalk" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}
 
- (void)testCrosswalk_ex2
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"factual_id"
                                                  equalTo:@"860fed91-3a52-44c8-af7b-8095eb943da1"]];    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"namespace"
                                                  equalTo:@"yelp"]];    
    
    [_apiObject queryTable:@"crosswalk" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testCrosswalk_ex3
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"namespace"
                                                  equalTo:@"foursquare"]];    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"namespace_id"
                                                  equalTo:@"4ae4df6df964a520019f21e3"]];    
    
    [_apiObject queryTable:@"crosswalk" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testCrosswalk_limit
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"factual_id"
                                                  equalTo:@"860fed91-3a52-44c8-af7b-8095eb943da1"]];
    queryObject.limit = 1;
    [_apiObject queryTable:@"crosswalk" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testMonetize
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"place_locality"
                                                  equalTo:@"Los Angeles"]];
    
    [_apiObject monetize:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testSelect
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"country"
                                                  equalTo:@"US"]];
    [queryObject addSelectTerm:@"address"];
    [queryObject addSelectTerm:@"country"];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testWorldGeographies
{
    FactualQuery* queryObject = [FactualQuery query];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"name"
                                                  equalTo:@"philadelphia"]];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"country"
                                                  equalTo:@"us"]];
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"placetype"
                                                  equalTo:@"locality"]];
    [_apiObject queryTable:@"world-geographies" optionalQueryParams:queryObject withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testResolve_ex1
{
    NSMutableDictionary* values  = [NSMutableDictionary dictionaryWithCapacity:4];
    [values setValue:@"McDonalds" forKey:@"name"];    
    [values setValue:@"10451 Santa Monica Blvd" forKey:@"address"];    
    [values setValue:@"CA" forKey:@"region"];    
    [values setValue:@"90025" forKey:@"postcode"];
    [_apiObject resolveRow:@"places" withValues:values withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
} 


- (void)testGeopulse
{
    CLLocationCoordinate2D point = {_latitude, _longitude};
    NSMutableArray* terms = [[NSMutableArray alloc] initWithCapacity:2];
    [terms addObject:@"area_statistics"];
    [terms addObject:@"race_and_ethnicity"];
    [_apiObject queryGeopulse:point selectTerms:terms withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testMatch
{
    NSMutableDictionary* values  = [NSMutableDictionary dictionaryWithCapacity:4];
    [values setValue:@"McDonalds" forKey:@"name"];    
    [values setValue:@"10451 Santa Monica Blvd" forKey:@"address"];    
    [values setValue:@"CA" forKey:@"region"];    
    [values setValue:@"90025" forKey:@"postcode"];
    [_apiObject matchRow:@"places" withValues:values withDelegate:self];
    
    [self waitForResponse];
    STAssertTrue([@"c730d193-ba4d-4e98-8620-29c672f2f117" isEqualToString:_matchResult], @"Match failed");
}

- (void)testSchema
{
    [_apiObject getTableSchema:@"restaurants-us" withDelegate:self];
    
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}


- (void)testGeocode
{
    CLLocationCoordinate2D point;
    point.longitude = _longitude;
    point.latitude = _latitude;
    [_apiObject reverseGeocode:point withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
}

- (void)testRawRead
{
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    [params setValue:@"3" forKey:@"limit"];
    [_apiObject get:@"t/places" params:params withDelegate: self];
    
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testRawReadComplex
{
    NSNumber* latValue = [NSNumber numberWithDouble:_latitude];
    NSNumber* longValue = [NSNumber numberWithDouble:_longitude];
    NSNumber* distanceValue = [NSNumber numberWithDouble:_meters];
    NSDictionary* geo = @{@"$circle": @{@"$center":@[latValue,longValue],
                                        @"$meters": distanceValue}};
    NSDictionary* params = @{@"geo" : geo,
                             @"q": @"Starbucks",
                             @"select": @"name,address,latitude,longitude,locality,postcode",
                             @"sort": @"$distance:asc",
                             @"limit": @"50"
                             };
    [_apiObject get:@"t/restaurants" params:params withDelegate: self];
    [self waitForResponse];
    STAssertTrue(_rawResult != nil, @"Invalid response");
}

 /*
- (void)testFlagDuplicate
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Duplicate tableId: @"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

 - (void)testFlagInaccurate
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Inaccurate tableId:@"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
}

- (void)testFlagInappropriate
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Inappropriate tableId: @"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
}

- (void)testFlagNonExistent
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Nonexistent tableId: @"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testFlagSpam
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Spam tableId: @"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testFlagOther
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    [_apiObject flagProblem:FactualFlagType_Other tableId: @"us-sandbox" factualId: @"158294f8-3300-4841-9e49-c23d5d670d07" metadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testSubmitAdd
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    
    NSMutableDictionary* values  = [NSMutableDictionary dictionaryWithCapacity:4];
    [values setValue:@"100" forKey:@"longitude"];   
    
    [_apiObject submitRow:@"us-sandbox" withValues:values withMetadata:metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testSubmitEdit
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    
    NSMutableDictionary* values  = [NSMutableDictionary dictionaryWithCapacity:4];
    [values setValue:@"100" forKey:@"longitude"];    
    
    [_apiObject submitRowWithId:@"158294f8-3300-4841-9e49-c23d5d670d07" tableId:@"us-sandbox" withValues:values withMetadata:metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
    
}

- (void)testSubmitDelete
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    
    NSMutableDictionary* values  = [NSMutableDictionary dictionaryWithCapacity:4];
    [values setValue:@"null" forKey:@"longitude"];    
    
    [_apiObject submitRowWithId:@"158294f8-3300-4841-9e49-c23d5d670d07" tableId:@"us-sandbox" withValues:values withMetadata:metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
 
}
 
*/

- (void)testClear
{
    FactualRowMetadata* metadata = [FactualRowMetadata metadata: @"testuser"];
    metadata.comment = @"my comment";
    metadata.reference = @"www.mytest.com";
    NSMutableArray* clearFields = [[NSMutableArray alloc] initWithCapacity:2];
    [clearFields addObject:@"longitude"];
    [clearFields addObject:@"latitude"];
    [_apiObject clearRowWithId: @"1d93c1ed-8cf3-4d58-94e0-05bbcd827cba" tableId: @"us-sandbox" withFields: clearFields withMetadata: metadata withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue(_rawResult != nil, @"Invalid response");
}

- (void)testFetchRow1
{
    NSString* factualId = @"0000022c-4ab3-4f5d-8e67-6a6ff1826a93";
    [_apiObject fetchRow:@"places" factualId:factualId withDelegate:self];
    [self waitForResponse];
    STAssertTrue([_queryResult.rows count] == 1, @"Row count not 1");
    FactualRow *firstRow = [_queryResult.rows objectAtIndex:0];
    STAssertTrue([factualId isEqualToString:[firstRow valueForName:@"factual_id"]], @"Fetch row id not equal to test factual id");
}

- (void)testFetchRow2
{
    NSMutableArray* onlyFields = [[NSMutableArray alloc] initWithCapacity:1];
    [onlyFields addObject:@"name"];
    
    NSString* factualId = @"0000022c-4ab3-4f5d-8e67-6a6ff1826a93";
    [_apiObject fetchRow:@"places" factualId:factualId only:onlyFields withDelegate:self];
    [self waitForResponse];
    STAssertTrue([_queryResult.rows count] == 1, @"Row count not 1");
    FactualRow *firstRow = [_queryResult.rows objectAtIndex:0];
    STAssertTrue([@"Icbm" isEqualToString:[firstRow valueForName:@"name"]], @"Fetch row id not equal to test factual id");
}

- (void)testIncludes1
{
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"category_ids"
                                                 includes:@"10"]];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
    for (FactualRow *row in _queryResult.rows) {
        NSArray *categoryIds = [row valueForName:@"category_ids"];
        bool found = false;
        for (NSNumber *categoryId in categoryIds) {
            if ([NSNumber numberWithInteger:10] == categoryId) {
                found = true;
                break;
            }
        }
        STAssertTrue(found, @"Category filter not returning correct results");
    }
}

- (void)testIncludes2
{
    NSMutableArray* categories = [[NSMutableArray alloc] initWithCapacity:2];
    [categories addObject:[NSNumber numberWithInteger:10]];
    [categories addObject:[NSNumber numberWithInteger:120]];
    
    FactualQuery* queryObject = [FactualQuery query];
    
    [queryObject addRowFilter:[FactualRowFilter fieldName:@"category_ids"
                                         includesAnyArray:categories]];
    [_apiObject queryTable:@"places" optionalQueryParams:queryObject withDelegate:self];
    [self waitForResponse];
    
    STAssertTrue([_queryResult.rows count] > 0, @"Invalid row count");
    
    for (FactualRow *row in _queryResult.rows) {
        NSArray *categoryIds = [row valueForName:@"category_ids"];
        bool found = false;
        for (NSNumber *categoryId in categoryIds) {
            if ([categories containsObject:categoryId]) {
                found = true;
                break;
            }
        }
        STAssertTrue(found, @"Category filter not returning correct results");
    }
}

- (void)waitForResponse
{
    while (!_finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) requestComplete:(FactualAPIRequest *)request receivedRawResult:(NSDictionary *)result {
    _rawResult = result;
    _finished = true;
    /*
     for (id key in result) {
        NSLog(@"KEY: %@, VALUE: %@", key, [result objectForKey:key]);
     }
     */
}

-(void) requestComplete:(FactualAPIRequest *)request receivedQueryResult:(FactualQueryResult *)queryResult {
    _queryResult = queryResult;
    _finished = true;
     for (id row in queryResult.rows) {
        NSLog(@"Row: %@", row);
     }
}

-(void) requestComplete:(FactualAPIRequest *)request receivedMatchResult:(NSString *)factualId {
    _matchResult = factualId;
    _finished = true;
}

-(void) requestComplete:(FactualAPIRequest *)request failedWithError:(NSError *)error {
    NSLog(@"FAILED with error");
    _finished = true;
}
@end
