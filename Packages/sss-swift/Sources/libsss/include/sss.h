/*
 * Swift bridging header for Daan Sprenkels' Shamir secret sharing library
 * Copyright (c) 2017 Daan Sprenkels <hello@dsprenkels.com>
 */


#ifndef sss_INCLUDE_SSS_H_
#define sss_INCLUDE_SSS_H_

#include "../sss.h"
#include "../hazmat.h"
#include <unistd.h>


/*
Swift does not reliably support constants defined by the preprocessor, so
we should define them as static constants.
(https://stackoverflow.com/q/24325477/5207081)
*/
const size_t sss_mlen = sss_MLEN;
const size_t sss_clen = sss_CLEN;
const size_t sss_share_len = sss_SHARE_LEN;
const size_t sss_keyshare_len = sss_KEYSHARE_LEN;


#endif /* sss_INCLUDE_SSS_H_ */
