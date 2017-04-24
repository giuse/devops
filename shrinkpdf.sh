#!/bin/bash
# shrinkpdf: an utility to make pdf smaller
#
# usage: `shrinkpdf mydoc.pdf` => `mydoc_small.pdf`
# if result is still too large, tweak the parameters below and try again

#### CONFIG
# QUALITY: a generic assessment of target quality
#   values: /screen -> /ebook -> /printer -> /prepress
QUALITY=/ebook
# IMGRES, FONTRES: resolution of image and fonts
#   lower the first in image-heavy docs (e.g. scans), the second in text-heavy
IMGRES=350
FONTRES=1200
# SAMPLE: sampling method, don't touch unless a run takes too much
SAMPLE=/Bicubic
####

INPUT_NAME="$1"
OUTPUT_NAME="${INPUT_NAME%.*}_small.pdf"

gs  -q -dNOPAUSE -dBATCH -dSAFER \
  -r${FONTRES} \
  -dColorImageDownsampleType=${SAMPLE} \
  -dColorImageResolution=${IMGRES} \
  -dGrayImageDownsampleType=${SAMPLE} \
  -dGrayImageResolution=${IMGRES} \
  -dMonoImageDownsampleType=${SAMPLE} \
  -dMonoImageResolution=${IMGRES} \
  -sDEVICE=pdfwrite \
  -dCompatibilityLevel=1.3 \
  -dPDFSETTINGS=${QUALITY} \
  -dEmbedAllFonts=true \
  -dSubsetFonts=true \
  -sOutputFile=${OUTPUT_NAME} \
  "$INPUT_NAME"


# IF EVERYTHING ELSE FAILS, check these out:
#
# convert -units PixelsPerInch myPic.pdf -density 300 fileout.pdf
#
# gs \
#   -o out300.png \
#   -sDEVICE=pngalpha \
#   -r300 \
#    input.pdf
#
# full options: http://milan.kupcevic.net/ghostscript-ps-pdf/
