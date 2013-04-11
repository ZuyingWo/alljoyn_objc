////////////////////////////////////////////////////////////////////////////////
// Copyright 2013, Qualcomm Innovation Center, Inc.
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

#import <Foundation/Foundation.h>
#import "AJNStatus.h"

@interface AJNPasswordManager

/**
 * Set credentials used for the authentication of thin clients.
 *
 * @param  authMechanism    The name of the authentication mechanism issuing the request.
 * @param  password         The password
 * @return  - ER_OK if the credentials was successfully set
 *
 */
+(QStatus)setCredentialsForAuthMechanism:(NSString *)authMechanism usingPassword:(NSString *)password;

@end