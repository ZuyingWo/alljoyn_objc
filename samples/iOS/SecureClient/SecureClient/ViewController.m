////////////////////////////////////////////////////////////////////////////////
// Copyright 2012, Qualcomm Innovation Center, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////////////////////////////////////////////////////////////////////////////////

#import "ViewController.h"
#import "AJNClientController.h"
#import "SecureObject.h"
#import "Constants.h"

@interface ViewController () <AJNClientDelegate, AJNAuthenticationListener>

@property (nonatomic, strong) SecureObjectProxy *secureObjectProxy;
@property (nonatomic, strong) AJNClientController *clientController;

- (AJNProxyBusObject *)proxyObjectOnBus:(AJNBusAttachment *)bus inSession:(AJNSessionId)sessionId;
- (void)shouldUnloadProxyObjectOnBus:(AJNBusAttachment *)bus;

- (void)didStartBus:(AJNBusAttachment *)bus;

@end

@implementation ViewController

@synthesize secureObjectProxy = _secureObjectProxy;
@synthesize startButton = _startButton;
@synthesize clientController = _clientController;
@synthesize password = _password;

- (NSString *)applicationName
{
    return kAppName;
}

- (NSString *)serviceName
{
    return kServiceName;
}

- (AJNBusNameFlag)serviceNameFlags
{
    return kAJNBusNameFlagDoNotQueue | kAJNBusNameFlagReplaceExisting;
}

- (AJNSessionPort)sessionPort
{
    return kServicePort;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // allocate the client bus controller and set bus properties
    //
    self.clientController = [[AJNClientController alloc] init];
    self.clientController.trafficType = kAJNTrafficMessages;
    self.clientController.proximityOptions = kAJNProximityAny;
    self.clientController.transportMask = kAJNTransportMaskAny;
    self.clientController.allowRemoteMessages = YES;
    self.clientController.multiPointSessionsEnabled = YES;
    self.clientController.delegate = self;
    
}

- (IBAction)didTouchStartButton:(id)sender
{
    if (self.clientController.bus.isStarted) {
        [self.clientController stop];
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    }
    else {
        [self.clientController start];
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)shouldUnloadProxyObjectOnBus:(AJNBusAttachment *)bus
{
    self.secureObjectProxy = nil;
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];        
}

- (AJNProxyBusObject *)proxyObjectOnBus:(AJNBusAttachment *)bus inSession:(AJNSessionId)sessionId
{
    self.secureObjectProxy = [[SecureObjectProxy alloc] initWithBusAttachment:bus serviceName:self.serviceName objectPath:kServicePath sessionId:sessionId];
    
    // now we need to authenticate
    //
    [self.secureObjectProxy secureConnection:YES];
    
    return self.secureObjectProxy;
}

- (void)didJoinInSession:(AJNSessionId)sessionId withService:(NSString *)serviceName
{
    NSString *pingString = @"Hello AllJoyn!";
    NSString *returnPingString;
    [self didReceiveStatusMessage:[NSString stringWithFormat:@"Sending ping string [%@]", pingString]];
    returnPingString = [self.secureObjectProxy sendPingString:pingString];
    [self didReceiveStatusMessage:[NSString stringWithFormat:@"Ping string returned [%@] from service and %@", returnPingString, returnPingString ? @"was successful" : @"failed"]];
    
    [self.clientController stop];
}

- (void)didStartBus:(AJNBusAttachment *)bus
{
    // enable security for the bus
    //
    NSString *keystoreFilePath = @"Documents/alljoyn_keystore/s_central.ks";
    QStatus status = [bus enablePeerSecurity:@"ALLJOYN_SRP_KEYX" authenticationListener:self keystoreFileName:keystoreFilePath sharing:YES];
    NSString *message;
    if (status != ER_OK) {
        message = [NSString stringWithFormat:@"ERROR: Failed to enable security on the bus. %@", [AJNStatus descriptionForStatusCode:status]];
    }
    else {
        message = @"Successfully enabled security for the bus";
    }
    NSLog(@"%@",message);
    [self didReceiveStatusMessage:message];
}

- (void)authenticationUsing:(NSString *)authenticationMechanism forRemotePeer:(NSString *)peerName didCompleteWithStatus:(BOOL)success
{
    NSString *message = [NSString stringWithFormat:@"Authentication %@ %@.", authenticationMechanism, success ? @"successful" : @"failed"];
    NSLog(@"%@", message);
    [self didReceiveStatusMessage:message];
}

- (AJNSecurityCredentials *)requestSecurityCredentialsWithAuthenticationMechanism:(NSString *)authenticationMechanism peerName:(NSString *)peerName authenticationCount:(uint16_t)authenticationCount userName:(NSString *)userName credentialTypeMask:(AJNSecurityCredentialType)mask
{
    NSLog(@"RequestCredentials for authenticating %@ using mechanism %@", peerName, authenticationMechanism);
    AJNSecurityCredentials *credentials = nil;
    if ([authenticationMechanism compare:@"ALLJOYN_SRP_KEYX"] == NSOrderedSame) {
        if (mask & kAJNSecurityCredentialTypePassword) {
            if (authenticationCount <= 3) {
                credentials = [[AJNSecurityCredentials alloc] init];
                credentials.password = self.password;
            }
        }
    }
    return credentials;
}

- (void)didReceiveStatusMessage:(NSString*)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableString *string = self.eventsTextView.text.length ? [self.eventsTextView.text mutableCopy] : [[NSMutableString alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [string appendFormat:@"[%@]\n",[formatter stringFromDate:[NSDate date]]];
        [string appendString:message];
        [string appendString:@"\n\n"];
        [self.eventsTextView setText:string];
        NSLog(@"%@",message);
        [self.eventsTextView scrollRangeToVisible:NSMakeRange([self.eventsTextView.text length], 0)];
    });
}


@end
