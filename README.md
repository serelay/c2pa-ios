# C2PA iOS

## ⚠️ This project is intended to be forked and will not be maintained here. ⚠️


Bootstrap for client-side asset creation for the Coalition for Content Provenance and 
Authenticity ([C2PA](https://c2pa.org)) standard. 

**This was created targeting C2PA Draft Specification v0.7 (C2PA PUBLIC DRAFT, 2021-08-31)**

The approach may also be applied to C2PA's predecessor CAI with minor client-side adjustments.

Privacy-respecting flow relies upon a level of trust between the device. e.g. via AppAttest. This version implicitly trusts the hashes provided by the client device. However, due to the cryptographic protections in place within C2PA specification the underlying asset is altered after the server request, then the C2PA validations will highlight this.

Alternatively, where the trust in the client environment is lower, the full image can be provided to the server toolkit, and appropriate hashes will be compiled. But rather than respond with a full-image download the server can respond with data portions and instructions to the client on where to insert them in the original asset.

It is good practice to retain control of signing keys off-device in case of abuse. This library intends to provide some tools for this.

## Usage

This is written as an individual module, with a reference AAR implementation in order to support a faster copy & paste into an existing project.

A reference implementation can be found in the `demo-app` module.

With Minimal adjustments this should be compatible with regular Java/Kotlin, outside of the Android ecosystem.

**Example flow**
* User selects image to create a C2PA assertion.
* Device calculates some C2PA information for a server module to use.

**Either**

**Scenario A (Server-side thumbnail generation)**
* Device requests signed C2PA information to write, providing original image.
* Server produces full C2PA information, with embedded thumbnail data.
* Device receives full C2PA information.
* Device processes information and writes content to a copy of the original file.

**Or**

**Scenario B (Client-side thumbnail generation)**
* Device creates thumbnail for C2PA from original asset.
* Device provides server with hash and thumbnail information points for C2PA generation.
* Server constructs C2PA information with placeholder data as the thumbnail portion.
* Server signs this, trusting the client-provided thumbnail hash and length.
* Device receives data with JUMBF thumbnail placeholder data omitted.
* Device augments JUMBF segments with real thumbnail data.
* Device writes XMP information and thumbnail-augmented JUMBF segments to a copy of the original file.

## Project Structure

* `ViewController.swift` details the process for creating a C2PA file.
* `C2PA/API` folder contain models which hold the data that would be sent to/received from the server module.
* `ThumbnailUtil.swift` offers tools to produce C2PA-compatible thumbnails. See note on thubnails below.
* `C2PACreator.swift` gives ability to create C2PA file with either local or remote thumbnails.
* `C2PAFileHelper.swift` retrieves information to provide the server for local thumbnail variant.
* `ThumbnailUtil.swift` provides tools for creating a C2PA thumbnail locally and calculating the hash for the server module.
* `AppNWriter.swift` a toolkit for inserting data (JUMBF as APP11, XMP as APP1) into JPEGs via streams.


## A note on Thumbnails
During development it was discovered that Thumbnails for the same source JPEG could differ (on Android) depending
on the device manufacturer, operating system version and model. This may exist on iOS too, but was not encountered.
This is in part due to JPEG being a lossy format, but also platform differences.

If the same device is creating the image and/or hashes, or thumbnails are stored differently 
it is likely that this requirement can be avoided.

`libjpeg-turbo` could be used to achieve consistent behaviour for this if required.

# Related projects

- [C2PA Android](https://github.com/serelay/c2pa-android)
- [C2PA iOS](https://github.com/serelay/c2pa-ios)
- [C2PA Node](https://github.com/serelay/c2pa-node)
- [C2PA Web](https://github.com/serelay/c2pa-web)

# Thanks

Thanks to [@IanField90](https://github.com/IanField90), [@iblamefish](https://github.com/iblamefish), [@lesh1k](https://github.com/lesh1k) for making this possible.