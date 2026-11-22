#!/usr/bin/env bash
# Regenerates the metadata test fixtures.
# Requires: imagemagick, exiftool, cjxl (libjxl-tools).
set -euo pipefail
cd "$(dirname "$0")"

convert -size 16x12 gradient:red-blue base.png
convert base.png base.jpg
exiftool -q -overwrite_original -Make=TestCam -Model=TC-1 -ISO=400 -Orientation#=6 base.jpg

# JPEG XL: raw Exif box, brotli-compressed (brob) Exif box, JPEG reconstruction
# container, and a bare codestream with no metadata boxes at all.
cjxl base.jpg exif.jxl --lossless_jpeg=0 -d 1 --compress_boxes=0 >/dev/null 2>&1
cjxl base.jpg exif-brob.jxl --lossless_jpeg=0 -d 1 --compress_boxes=1 >/dev/null 2>&1
cjxl base.jpg exif-jpeg-recon.jxl --lossless_jpeg=1 >/dev/null 2>&1
cjxl base.png bare.jxl -d 1 >/dev/null 2>&1

# TIFFs with an embedded XMP packet (tag 700), as Lightroom writes into NEF/TIFF.
convert -size 8x8 xc:gray tiff-plain.tif
cp tiff-plain.tif xmp-rated.tif
cp tiff-plain.tif xmp-rejected.tif
exiftool -q -overwrite_original -Make=TestCam tiff-plain.tif
exiftool -q -overwrite_original -Make=TestCam -XMP-xmp:Rating=3 -XMP-xmp:Label=Red \
  -XMP-dc:Subject=landscape -XMP-dc:Subject=mountains xmp-rated.tif
exiftool -q -overwrite_original -XMP-xmp:Rating=-1 xmp-rejected.tif

rm base.png
