//------------------------------------------------------------------------------
// Author    : Andreas Buerkler
// Date      : 27.12.2018
// Filename  : typedefinitions.h
// Changelog : 27.12.2018 - file created
//------------------------------------------------------------------------------

#ifndef TYPEDEFINITIONS_H
#define TYPEDEFINITIONS_H

// error codes
static const int AUDIO_SUCCESS               = 0;
static const int AUDIO_LENGTH_ERROR          = 1;
static const int AUDIO_TIMEOUT_ERROR         = 2;
static const int AUDIO_TYPE_ERROR            = 3;
static const int AUDIO_RECEIVED_LENGTH_ERROR = 4;
static const int AUDIO_PACKET_LENGTH_ERROR   = 5;
static const int AUDIO_DATA_FORMAT_ERROR     = 6;
static const int AUDIO_ADDRESS_FORMAT_ERROR  = 7;

// packet types
static const char UDP_READ          = 0x01;
static const char UDP_WRITE         = 0x02;
static const char UDP_READ_RESPONSE = 0x04;
static const char UDP_READ_TIMEOUT  = 0x08;

// error code translator
#define errorToString(a) (a == AUDIO_SUCCESS)               ? "successful" : \
                         (a == AUDIO_LENGTH_ERROR)          ? "error: too much data requested" : \
                         (a == AUDIO_TIMEOUT_ERROR)         ? "error: timeout" : \
                         (a == AUDIO_TYPE_ERROR)            ? "error: wrong packet type received" : \
                         (a == AUDIO_RECEIVED_LENGTH_ERROR) ? "error: wrong length received" : \
                         (a == AUDIO_PACKET_LENGTH_ERROR)   ? "error: received packet too short" : \
                         (a == AUDIO_DATA_FORMAT_ERROR)     ? "error: data format wrong" : \
                         (a == AUDIO_ADDRESS_FORMAT_ERROR)  ? "error: address format wrong" : \
                                                              "error: unknown"

#endif // TYPEDEFINITIONS_H
